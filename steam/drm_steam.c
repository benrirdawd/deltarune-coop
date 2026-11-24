// drm_steam.dll: a small GameMaker extension that lets DELTARUNE Online play over Steam
// (lobbies to find each other, Steam's relayed peer-to-peer messages to talk: no port forwarding).
//
// It talks to Valve's steam_api64.dll (next to this DLL, as drm_steam_api64.dll) through its flat C API, loaded at run
// time: without Steam running or without that DLL every function just answers 0 and the game
// plays as before over UDP. The app is Spacewar (480), Valve's free test app, so nobody needs to
// own anything.
//
// GameMaker extension functions only pass doubles and strings: Steam's 64-bit ids are kept here
// and the game sees small peer numbers (0..31), or ids written out as decimal strings.
//
// Build: zig cc -shared -O2 -target x86_64-windows-gnu -o drm_steam.dll drm_steam.c
#include <windows.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>

#define EXPORT __declspec(dllexport)
#define APP_ID 480
#define LOBBY_KEY "drm_online"   // every lobby of ours has this set to "1"
#define CODE_KEY "drm_code"

typedef uint64_t u64;
typedef int32_t HSteamPipe;
// Steam's C++ bool: one byte. (Declared as int, the rest of the return register is garbage.)
typedef uint8_t sbool;

// ---- Steam types used here (layouts from the Steamworks SDK 1.57 headers, x64) ----
typedef struct { int32_t eType; int32_t cbSize; char data[128]; } NetIdentity; // SteamNetworkingIdentity
typedef struct NetMsg {
    void *pData; int32_t cbSize; uint32_t conn; NetIdentity peer; int64_t connUserData;
    int64_t usecTimeReceived; int64_t messageNumber; void (*pfnFreeData)(struct NetMsg *);
    void (*pfnRelease)(struct NetMsg *); int32_t channel; int32_t flags; int64_t userData; uint16_t lane;
} NetMsg;
typedef struct { int32_t hSteamUser; int32_t iCallback; uint8_t *pubParam; int32_t cubParam; } CallbackMsg;
typedef struct { u64 gameID; uint32_t gameIP; uint16_t gamePort; uint16_t queryPort; u64 lobby; } FriendGameInfo;
typedef struct { u64 hAsyncCall; int32_t iCallback; uint32_t cubParam; } CallCompleted;   // 703
typedef struct { int32_t result; u64 lobby; } LobbyCreated;                              // 513
typedef struct { u64 lobby; uint32_t perms; uint8_t locked; uint32_t response; } LobbyEnter; // 504
typedef struct { uint32_t count; } LobbyMatchList;                                        // 510
typedef struct { u64 lobby; u64 friendId; } JoinRequested;                                // 333
typedef struct { NetIdentity remote; } SessionRequest;                                    // 1251

// ---- the flat API, looked up in steam_api64.dll ----
static HMODULE g_lib;
static sbool (*p_Init)(void);
static void (*p_Shutdown)(void);
static HSteamPipe (*p_GetPipe)(void);
static void (*p_MD_Init)(void);
static void (*p_MD_RunFrame)(HSteamPipe);
static sbool (*p_MD_Next)(HSteamPipe, CallbackMsg *);
static void (*p_MD_Free)(HSteamPipe);
static sbool (*p_MD_CallResult)(HSteamPipe, u64, void *, int, int, sbool *);
static void *(*p_Matchmaking)(void);
static void *(*p_Friends)(void);
static void *(*p_User)(void);
static void *(*p_NetMsgs)(void);
static void *(*p_NetUtils)(void);
static u64 (*p_CreateLobby)(void *, int, int);
static u64 (*p_JoinLobby)(void *, u64);
static void (*p_LeaveLobby)(void *, u64);
static u64 (*p_RequestLobbyList)(void *);
static void (*p_ListStringFilter)(void *, const char *, const char *, int);
static void (*p_ListDistance)(void *, int);
static void (*p_ListCount)(void *, int);
static u64 (*p_LobbyByIndex)(void *, int);
static sbool (*p_SetLobbyData)(void *, u64, const char *, const char *);
static const char *(*p_GetLobbyData)(void *, u64, const char *);
static u64 (*p_LobbyOwner)(void *, u64);
static int (*p_NumMembers)(void *, u64);
static u64 (*p_MemberByIndex)(void *, u64, int);
static const char *(*p_PersonaName)(void *);
static int (*p_FriendCount)(void *, int);
static u64 (*p_FriendByIndex)(void *, int, int);
static sbool (*p_FriendGame)(void *, u64, FriendGameInfo *);
static const char *(*p_FriendName)(void *, u64);
static u64 (*p_MySteamID)(void *);
static int (*p_Send)(void *, const NetIdentity *, const void *, uint32_t, int, int);
static int (*p_Recv)(void *, int, NetMsg **, int);
static sbool (*p_Accept)(void *, const NetIdentity *);
static sbool (*p_Close)(void *, const NetIdentity *);
static void (*p_IdSet64)(NetIdentity *, u64);
static u64 (*p_IdGet64)(NetIdentity *);
static void (*p_InitRelay)(void *);

static int g_ok;                 // Steam is up
static HSteamPipe g_pipe;
static void *g_mm, *g_fr, *g_us, *g_nm;
static u64 g_lobby;              // the lobby I'm in (0: none)
static u64 g_call_create, g_call_join, g_call_list;
static char g_err[256];

// Peers: index <-> Steam id.
#define MAXPEERS 32
static u64 g_peer[MAXPEERS];
static int g_npeers;

// Events for the game, read one at a time (drs_event).
#define MAXEV 64
static char g_ev[MAXEV][128];
static int g_ev_head, g_ev_tail;
static char g_out[512];          // returned strings

// Friends playing (filled by drs_friends_refresh).
#define MAXFR 64
static u64 g_fr_lobby[MAXFR];
static char g_fr_name[MAXFR][64];
static int g_nfr;

static void push_event(const char *fmt, ...)
{
    int next = (g_ev_tail + 1) % MAXEV;
    if (next == g_ev_head)
        return;
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(g_ev[g_ev_tail], sizeof g_ev[0], fmt, ap);
    va_end(ap);
    g_ev_tail = next;
}

static int peer_index(u64 id, int add)
{
    for (int i = 0; i < g_npeers; i++)
        if (g_peer[i] == id)
            return i;
    if (!add || g_npeers >= MAXPEERS)
        return -1;
    g_peer[g_npeers] = id;
    return g_npeers++;
}

// Session requests from Steam users not (yet) in my lobby: looked at again for 10 s.
#define MAXPEND 8
static u64 g_pend[MAXPEND];
static DWORD g_pend_t[MAXPEND];

static int in_lobby(u64 id)
{
    if (!g_lobby || !id)
        return 0;
    int n = p_NumMembers(g_mm, g_lobby);
    for (int i = 0; i < n; i++)
        if (p_MemberByIndex(g_mm, g_lobby, i) == id)
            return 1;
    return 0;
}

static int allowed(u64 id)
{
    return peer_index(id, 0) >= 0 || in_lobby(id);
}

static void pending_add(u64 id)
{
    int slot = 0;
    for (int i = 0; i < MAXPEND; i++)
    {
        if (g_pend[i] == id || !g_pend[i]) { slot = i; break; }
        if (g_pend_t[i] < g_pend_t[slot]) slot = i;
    }
    g_pend[slot] = id;
    g_pend_t[slot] = GetTickCount();
}

static void pending_tick(void)
{
    for (int i = 0; i < MAXPEND; i++)
    {
        if (!g_pend[i])
            continue;
        if (allowed(g_pend[i]))
        {
            NetIdentity id;
            memset(&id, 0, sizeof id);
            p_IdSet64(&id, g_pend[i]);
            p_Accept(g_nm, &id);
            g_pend[i] = 0;
        }
        else if (GetTickCount() - g_pend_t[i] > 10000)
            g_pend[i] = 0;
    }
}

#define LOAD(var, name) if (!(*(void **)&var = (void *)GetProcAddress(g_lib, name))) { snprintf(g_err, sizeof g_err, "steam_api64.dll has no %s", name); return 0; }

static int load_api(void)
{
    // steam_api64.dll from this DLL's own folder.
    char path[MAX_PATH];
    HMODULE self = NULL;
    GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT, (LPCSTR)&load_api, &self);
    DWORD n = GetModuleFileNameA(self, path, MAX_PATH);
    while (n > 0 && path[n - 1] != '\\' && path[n - 1] != '/')
        n--;
    path[n] = 0;
    // (The mod's copy has its own name, so it never replaces a steam_api64.dll the game has.)
    size_t dirlen = strlen(path);
    strncat(path, "drm_steam_api64.dll", MAX_PATH - dirlen - 1);
    g_lib = LoadLibraryA(path);
    if (!g_lib)
    {
        path[dirlen] = 0;
        strncat(path, "steam_api64.dll", MAX_PATH - dirlen - 1);
        g_lib = LoadLibraryA(path);
    }
    if (!g_lib)
        g_lib = LoadLibraryA("steam_api64.dll");
    if (!g_lib)
    {
        snprintf(g_err, sizeof g_err, "steam_api64.dll not found");
        return 0;
    }
    LOAD(p_Init, "SteamAPI_Init"); LOAD(p_Shutdown, "SteamAPI_Shutdown"); LOAD(p_GetPipe, "SteamAPI_GetHSteamPipe");
    LOAD(p_MD_Init, "SteamAPI_ManualDispatch_Init"); LOAD(p_MD_RunFrame, "SteamAPI_ManualDispatch_RunFrame");
    LOAD(p_MD_Next, "SteamAPI_ManualDispatch_GetNextCallback"); LOAD(p_MD_Free, "SteamAPI_ManualDispatch_FreeLastCallback");
    LOAD(p_MD_CallResult, "SteamAPI_ManualDispatch_GetAPICallResult");
    LOAD(p_Matchmaking, "SteamAPI_SteamMatchmaking_v009"); LOAD(p_Friends, "SteamAPI_SteamFriends_v017");
    LOAD(p_User, "SteamAPI_SteamUser_v023"); LOAD(p_NetMsgs, "SteamAPI_SteamNetworkingMessages_SteamAPI_v002");
    LOAD(p_NetUtils, "SteamAPI_SteamNetworkingUtils_SteamAPI_v004");
    LOAD(p_CreateLobby, "SteamAPI_ISteamMatchmaking_CreateLobby"); LOAD(p_JoinLobby, "SteamAPI_ISteamMatchmaking_JoinLobby");
    LOAD(p_LeaveLobby, "SteamAPI_ISteamMatchmaking_LeaveLobby"); LOAD(p_RequestLobbyList, "SteamAPI_ISteamMatchmaking_RequestLobbyList");
    LOAD(p_ListStringFilter, "SteamAPI_ISteamMatchmaking_AddRequestLobbyListStringFilter");
    LOAD(p_ListDistance, "SteamAPI_ISteamMatchmaking_AddRequestLobbyListDistanceFilter");
    LOAD(p_ListCount, "SteamAPI_ISteamMatchmaking_AddRequestLobbyListResultCountFilter");
    LOAD(p_LobbyByIndex, "SteamAPI_ISteamMatchmaking_GetLobbyByIndex"); LOAD(p_SetLobbyData, "SteamAPI_ISteamMatchmaking_SetLobbyData");
    LOAD(p_GetLobbyData, "SteamAPI_ISteamMatchmaking_GetLobbyData"); LOAD(p_LobbyOwner, "SteamAPI_ISteamMatchmaking_GetLobbyOwner");
    LOAD(p_NumMembers, "SteamAPI_ISteamMatchmaking_GetNumLobbyMembers"); LOAD(p_MemberByIndex, "SteamAPI_ISteamMatchmaking_GetLobbyMemberByIndex");
    LOAD(p_PersonaName, "SteamAPI_ISteamFriends_GetPersonaName"); LOAD(p_FriendCount, "SteamAPI_ISteamFriends_GetFriendCount");
    LOAD(p_FriendByIndex, "SteamAPI_ISteamFriends_GetFriendByIndex"); LOAD(p_FriendGame, "SteamAPI_ISteamFriends_GetFriendGamePlayed");
    LOAD(p_FriendName, "SteamAPI_ISteamFriends_GetFriendPersonaName"); LOAD(p_MySteamID, "SteamAPI_ISteamUser_GetSteamID");
    LOAD(p_Send, "SteamAPI_ISteamNetworkingMessages_SendMessageToUser");
    LOAD(p_Recv, "SteamAPI_ISteamNetworkingMessages_ReceiveMessagesOnChannel");
    LOAD(p_Accept, "SteamAPI_ISteamNetworkingMessages_AcceptSessionWithUser");
    LOAD(p_Close, "SteamAPI_ISteamNetworkingMessages_CloseSessionWithUser");
    LOAD(p_IdSet64, "SteamAPI_SteamNetworkingIdentity_SetSteamID64"); LOAD(p_IdGet64, "SteamAPI_SteamNetworkingIdentity_GetSteamID64");
    LOAD(p_InitRelay, "SteamAPI_ISteamNetworkingUtils_InitRelayNetworkAccess");
    return 1;
}

// 1 when Steam is up (Steam must be running and logged in); safe to call again.
EXPORT double drs_init(void)
{
    if (g_ok)
        return 1;
    if (!g_lib && !load_api())
        return 0;
    // The app id without a steam_appid.txt file (the game's folder may not be writable).
    SetEnvironmentVariableA("SteamAppId", "480");
    SetEnvironmentVariableA("SteamGameId", "480");
    if (!p_Init())
    {
        snprintf(g_err, sizeof g_err, "Steam is not running (or not logged in)");
        return 0;
    }
    p_MD_Init();
    g_pipe = p_GetPipe();
    g_mm = p_Matchmaking(); g_fr = p_Friends(); g_us = p_User(); g_nm = p_NetMsgs();
    p_InitRelay(p_NetUtils());
    g_ok = 1;
    return 1;
}

EXPORT const char *drs_error(void) { return g_err; }

EXPORT const char *drs_my_name(void)
{
    if (!g_ok) return "";
    snprintf(g_out, sizeof g_out, "%s", p_PersonaName(g_fr));
    return g_out;
}

static void on_call_result(CallCompleted *cc)
{
    uint8_t buf[512];
    sbool bad = 0;
    int failed = 0;
    if (cc->cubParam > sizeof buf || !p_MD_CallResult(g_pipe, cc->hAsyncCall, buf, cc->cubParam, cc->iCallback, &bad) || bad)
        failed = 1;
    if (cc->hAsyncCall == g_call_create)
    {
        g_call_create = 0;
        LobbyCreated *r = (LobbyCreated *)buf;
        if (failed || r->result != 1)
            push_event("host_failed %d", failed ? -1 : r->result);
        // (the lobby itself is reported by LobbyEnter)
    }
    else if (cc->hAsyncCall == g_call_list)
    {
        g_call_list = 0;
        int n = failed ? 0 : (int)((LobbyMatchList *)buf)->count;
        if (n > 0)
        {
            u64 l = p_LobbyByIndex(g_mm, 0);
            push_event("code_found %llu", (unsigned long long)l);
            g_call_join = p_JoinLobby(g_mm, l);
        }
        else
            push_event("code_not_found");
    }
    else if (cc->hAsyncCall == g_call_join)
    {
        g_call_join = 0;
        LobbyEnter *e = (LobbyEnter *)buf;
        if (failed || e->response != 1)
            push_event("join_failed %d", failed ? -1 : (int)e->response);
    }
}

static void on_callback(CallbackMsg *m)
{
    switch (m->iCallback)
    {
    case 703:
        on_call_result((CallCompleted *)m->pubParam);
        break;
    case 504: { // LobbyEnter: as host (after creating it) or as a joiner
        LobbyEnter *e = (LobbyEnter *)m->pubParam;
        if (e->response != 1)
            break;
        g_lobby = e->lobby;
        u64 owner = p_LobbyOwner(g_mm, e->lobby);
        if (owner == p_MySteamID(g_us))
            push_event("hosting");
        else
        {
            int pi = peer_index(owner, 1);
            push_event("joined %d", pi);
        }
        break;
    }
    case 333: { // a friend's "Join game" in Steam
        JoinRequested *j = (JoinRequested *)m->pubParam;
        push_event("join_request %llu", (unsigned long long)j->lobby);
        break;
    }
    case 1251: { // someone wants to talk to me: only players in my lobby (or already my peers)
        SessionRequest *s = (SessionRequest *)m->pubParam;
        u64 who = p_IdGet64(&s->remote);
        if (allowed(who))
            p_Accept(g_nm, &s->remote);
        else
            pending_add(who); // (they may have just joined: the lobby's member list can come a moment later)
        break;
    }
    case 1252:
        push_event("session_failed");
        break;
    }
}

// Runs Steam's callbacks: once a frame.
EXPORT double drs_tick(void)
{
    if (!g_ok) return 0;
    CallbackMsg m;
    p_MD_RunFrame(g_pipe);
    while (p_MD_Next(g_pipe, &m))
    {
        on_callback(&m);
        p_MD_Free(g_pipe);
    }
    pending_tick();
    return 1;
}

// The next event ("" when none): hosting | host_failed <r> | joined <peer> | join_failed <r> |
// code_found <lobby> | code_not_found | join_request <lobby> | session_failed
EXPORT const char *drs_event(void)
{
    if (g_ev_head == g_ev_tail)
        return "";
    snprintf(g_out, sizeof g_out, "%s", g_ev[g_ev_head]);
    g_ev_head = (g_ev_head + 1) % MAXEV;
    return g_out;
}

// Opens a lobby (public, so a code finds it) with the join code in its data.
EXPORT double drs_host(const char *code, double maxmembers)
{
    if (!g_ok) return 0;
    if (g_lobby) { p_LeaveLobby(g_mm, g_lobby); g_lobby = 0; }
    g_npeers = 0;
    g_call_create = p_CreateLobby(g_mm, 2 /* public */, (int)maxmembers);
    snprintf(g_out, sizeof g_out, "%s", code);
    return g_call_create != 0;
}

// Once hosting: writes the lobby's data (call after the "hosting" event).
EXPORT double drs_lobby_set(const char *key, const char *value)
{
    if (!g_ok || !g_lobby) return 0;
    return p_SetLobbyData(g_mm, g_lobby, key, value);
}

// Looks for a lobby of ours with this code, and joins it (events code_found/not_found, joined).
EXPORT double drs_join_code(const char *code)
{
    if (!g_ok) return 0;
    if (g_lobby) { p_LeaveLobby(g_mm, g_lobby); g_lobby = 0; }
    g_npeers = 0;
    p_ListStringFilter(g_mm, LOBBY_KEY, "1", 0);
    p_ListStringFilter(g_mm, CODE_KEY, code, 0);
    p_ListDistance(g_mm, 3 /* worldwide */);
    p_ListCount(g_mm, 1);
    g_call_list = p_RequestLobbyList(g_mm);
    return g_call_list != 0;
}

// Joins a lobby by its id (decimal string): a friend's lobby, or a Steam join request.
EXPORT double drs_join_lobby(const char *lobby)
{
    if (!g_ok) return 0;
    u64 l = _strtoui64(lobby, NULL, 10);
    if (!l) return 0;
    if (g_lobby) { p_LeaveLobby(g_mm, g_lobby); g_lobby = 0; }
    g_npeers = 0;
    g_call_join = p_JoinLobby(g_mm, l);
    return g_call_join != 0;
}

EXPORT double drs_leave(void)
{
    if (!g_ok) return 0;
    for (int i = 0; i < g_npeers; i++)
    {
        NetIdentity id;
        memset(&id, 0, sizeof id);
        p_IdSet64(&id, g_peer[i]);
        p_Close(g_nm, &id);
    }
    g_npeers = 0;
    if (g_lobby) { p_LeaveLobby(g_mm, g_lobby); g_lobby = 0; }
    return 1;
}

// Friends who are in a Spacewar lobby right now; then drs_friend_name / drs_friend_lobby.
EXPORT double drs_friends_refresh(void)
{
    if (!g_ok) return 0;
    g_nfr = 0;
    int n = p_FriendCount(g_fr, 4 /* immediate: real friends */);
    for (int i = 0; i < n && g_nfr < MAXFR; i++)
    {
        u64 f = p_FriendByIndex(g_fr, i, 4);
        FriendGameInfo gi;
        memset(&gi, 0, sizeof gi);
        if (!p_FriendGame(g_fr, f, &gi))
            continue;
        if ((gi.gameID & 0xFFFFFF) != APP_ID || gi.lobby == 0)
            continue;
        g_fr_lobby[g_nfr] = gi.lobby;
        snprintf(g_fr_name[g_nfr], sizeof g_fr_name[0], "%s", p_FriendName(g_fr, f));
        g_nfr++;
    }
    return g_nfr;
}

EXPORT const char *drs_friend_name(double i)
{
    int k = (int)i;
    return (k >= 0 && k < g_nfr) ? g_fr_name[k] : "";
}

EXPORT const char *drs_friend_lobby(double i)
{
    int k = (int)i;
    if (k < 0 || k >= g_nfr) return "";
    snprintf(g_out, sizeof g_out, "%llu", (unsigned long long)g_fr_lobby[k]);
    return g_out;
}

// Sends n bytes from a GameMaker buffer (buffer_get_address) to a peer, unreliably: the game
// keeps its own acknowledgements and resends, as over UDP.
EXPORT double drs_send(double peer, const char *data, double n)
{
    int k = (int)peer;
    if (!g_ok || k < 0 || k >= g_npeers || n <= 0) return 0;
    NetIdentity id;
    memset(&id, 0, sizeof id);
    p_IdSet64(&id, g_peer[k]);
    // 1 = unreliable, no Nagle delay; 32 = restart a broken session by itself
    return p_Send(g_nm, &id, data, (uint32_t)n, 1 | 32, 0) == 1;
}

static int g_last_peer = -1;

// The next message into a GameMaker buffer (buffer_get_address, room for max bytes): its size,
// 0 when there is none (then drs_recv_peer() is the sender's peer number).
EXPORT double drs_recv(char *dest, double max)
{
    if (!g_ok) return 0;
    for (;;)
    {
        NetMsg *m = NULL;
        if (p_Recv(g_nm, 0, &m, 1) <= 0 || !m)
            return 0;
        u64 from = p_IdGet64(&m->peer);
        // (Only players in my lobby, or already my peers, become peers.)
        int k = peer_index(from, allowed(from));
        int n = m->cbSize;
        if (k < 0 || n <= 0 || n > (int)max)
        {
            m->pfnRelease(m);
            continue;
        }
        memcpy(dest, m->pData, n);
        m->pfnRelease(m);
        g_last_peer = k;
        return n;
    }
}

EXPORT double drs_recv_peer(void) { return g_last_peer; }

// A peer's Steam name.
EXPORT const char *drs_peer_name(double peer)
{
    int k = (int)peer;
    if (!g_ok || k < 0 || k >= g_npeers) return "";
    snprintf(g_out, sizeof g_out, "%s", p_FriendName(g_fr, g_peer[k]));
    return g_out;
}

EXPORT double drs_in_lobby(void) { return g_lobby != 0; }

// A value of the lobby I'm in ("" when none): a joiner reads the host's code, to find the game
// again after a chapter change.
EXPORT const char *drs_lobby_get(const char *key)
{
    if (!g_ok || !g_lobby) return "";
    const char *v = p_GetLobbyData(g_mm, g_lobby, key);
    return v ? v : "";
}

// ---------------------------------------------------------------- bug report zip
// (Not Steam: it lives here because this is the mod's only DLL.) F9 "Save logs for a bug report":
// multiplayer_log.txt, multiplayer_log_prev.txt (the session before: the one that crashed, after a
// restart) and multiplayer_crash.txt from the save folder, in one zip on the desktop (or out_dir).
// Stored, not compressed: a few MB of text, and no zlib needed. Returns the zip's path, "" on error.
#include <shlobj.h>

static uint32_t zcrc(const unsigned char *p, size_t n)
{
    uint32_t c = 0xFFFFFFFFu;
    for (size_t i = 0; i < n; i++)
    {
        c ^= p[i];
        for (int k = 0; k < 8; k++) c = (c >> 1) ^ (0xEDB88320u & (0u - (c & 1u)));
    }
    return ~c;
}

static void zw16(FILE *f, unsigned v) { fputc(v & 255, f); fputc((v >> 8) & 255, f); }
static void zw32(FILE *f, uint32_t v) { zw16(f, v & 0xFFFF); zw16(f, v >> 16); }

static unsigned char *zread(const wchar_t *path, size_t *n)
{
    FILE *f = _wfopen(path, L"rb");
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    long len = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (len < 0 || len > 64 * 1024 * 1024) { fclose(f); return NULL; }
    unsigned char *b = (unsigned char *)malloc(len ? (size_t)len : 1);
    if (b && fread(b, 1, (size_t)len, f) != (size_t)len) { free(b); b = NULL; }
    fclose(f);
    *n = (size_t)len;
    return b;
}

EXPORT const char *drs_report_zip(const char *save_dir, const char *out_dir)
{
    static const char *names[] = { "multiplayer_log.txt", "multiplayer_log_prev.txt", "multiplayer_crash.txt" };
    wchar_t wsave[MAX_PATH], wout[MAX_PATH], wzip[MAX_PATH + 64], wf[MAX_PATH + 64];
    g_out[0] = 0;
    if (!MultiByteToWideChar(CP_UTF8, 0, save_dir, -1, wsave, MAX_PATH)) { snprintf(g_err, sizeof g_err, "bad save folder"); return ""; }
    if (out_dir && out_dir[0])
        MultiByteToWideChar(CP_UTF8, 0, out_dir, -1, wout, MAX_PATH);
    else if (SHGetFolderPathW(NULL, CSIDL_DESKTOPDIRECTORY, NULL, 0, wout) != S_OK)
    { snprintf(g_err, sizeof g_err, "no desktop folder"); return ""; }
    size_t ls = wcslen(wsave), lo = wcslen(wout);
    if (ls && wsave[ls - 1] != 92 && wsave[ls - 1] != L'/') wcscat(wsave, L"\\");
    if (lo && wout[lo - 1] != 92 && wout[lo - 1] != L'/') wcscat(wout, L"\\");
    SYSTEMTIME t;
    GetLocalTime(&t);
    swprintf(wzip, MAX_PATH + 64, L"%lsDELTARUNE-Online-logs-%04d%02d%02d-%02d%02d%02d.zip", wout, t.wYear, t.wMonth, t.wDay, t.wHour, t.wMinute, t.wSecond);
    FILE *z = _wfopen(wzip, L"wb");
    if (!z) { snprintf(g_err, sizeof g_err, "can't write the zip"); return ""; }
    unsigned dtime = (t.wHour << 11) | (t.wMinute << 5) | (t.wSecond / 2);
    unsigned ddate = ((t.wYear - 1980) << 9) | (t.wMonth << 5) | t.wDay;
    uint32_t offs[3], crcs[3], sizes[3];
    int have[3] = { 0, 0, 0 }, count = 0;
    for (int i = 0; i < 3; i++)
    {
        swprintf(wf, MAX_PATH + 64, L"%ls%hs", wsave, names[i]);
        size_t n = 0;
        unsigned char *b = zread(wf, &n);
        if (!b) continue;
        have[i] = 1; count++;
        offs[i] = (uint32_t)ftell(z); crcs[i] = zcrc(b, n); sizes[i] = (uint32_t)n;
        unsigned nl = (unsigned)strlen(names[i]);
        zw32(z, 0x04034b50); zw16(z, 10); zw16(z, 0); zw16(z, 0); zw16(z, dtime); zw16(z, ddate);
        zw32(z, crcs[i]); zw32(z, sizes[i]); zw32(z, sizes[i]); zw16(z, nl); zw16(z, 0);
        fwrite(names[i], 1, nl, z);
        fwrite(b, 1, n, z);
        free(b);
    }
    uint32_t cd = (uint32_t)ftell(z);
    for (int i = 0; i < 3; i++)
    {
        if (!have[i]) continue;
        unsigned nl = (unsigned)strlen(names[i]);
        zw32(z, 0x02014b50); zw16(z, 20); zw16(z, 10); zw16(z, 0); zw16(z, 0); zw16(z, dtime); zw16(z, ddate);
        zw32(z, crcs[i]); zw32(z, sizes[i]); zw32(z, sizes[i]); zw16(z, nl); zw16(z, 0); zw16(z, 0);
        zw16(z, 0); zw16(z, 0); zw32(z, 0); zw32(z, offs[i]);
        fwrite(names[i], 1, nl, z);
    }
    uint32_t cdlen = (uint32_t)ftell(z) - cd;
    zw32(z, 0x06054b50); zw16(z, 0); zw16(z, 0); zw16(z, count); zw16(z, count); zw32(z, cdlen); zw32(z, cd); zw16(z, 0);
    fclose(z);
    if (count == 0) { _wremove(wzip); snprintf(g_err, sizeof g_err, "no log files found"); return ""; }
    WideCharToMultiByte(CP_UTF8, 0, wzip, -1, g_out, sizeof g_out, NULL, NULL);
    return g_out;
}
