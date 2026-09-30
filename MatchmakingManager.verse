using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }
using { /Fortnite.com/Characters }
using { /Verse.org/Random }

matchmaking_manager := class(creative_device):
    @editable:
        ToolTip := MatchSettingsInfo
    MatchSettings : match_settings = match_settings{}

    @editable:
        ToolTip := MapManagerInfo
    MapManager : map_manager = map_manager{}

    @editable:
        ToolTip := LoadoutManagerInfo
    LoadoutManager : loadout_manager = loadout_manager{}

    @editable:
        ToolTip := StatsManagerInfo
    StatsManager : stats_manager = stats_manager{}

    @editable:
        ToolTip := MatchmakingCheckIntervalInfo
    MatchmakingCheckInterval : float = 5.0

    @editable:
        ToolTip := QueueSelectionWindowInfo
    QueueSelectionWindow : int = 6

    @editable:
        ToolTip := ReadyButtonInfo
    ReadyUpButton : button_device = button_device{}

    @editable:
        ToolTip := LobbyTPInfo
    LobbyTP : teleporter_device = teleporter_device{}

    var Queue : []agent = array{}
    var QueueEntryTimes : [agent]float = map{}
    var LockedAgents : []agent = array{}

    # Event signaled when a match is found from the queue (P1, P2, MapName, Arena)
    MatchFoundEvent<public> : event(tuple(agent, agent, string, arena_map)) = event(tuple(agent, agent, string, arena_map)){}
    LockAgents<public>(A : agent, B : agent) : void = set LockedAgents += array{A, B}
    UnlockAgent<public>(A : agent) : void = set LockedAgents = for (L : LockedAgents, L <> A) do L

    OnBegin<override>()<suspends> : void =
        ReadyUpButton.InteractedWithEvent.Subscribe(HandlePlayerReadyUp)
        GetPlayspace().PlayerRemovedEvent().Subscribe(OnPlayerLeftServer)
        spawn { MatchmakingLoop() }

    OnPlayerLeftServer(P : player) : void =
        set Queue = for (QueuedPlayer : Queue, QueuedPlayer <> P) do QueuedPlayer
        UnlockAgent(P)

    HandlePlayerReadyUp(Agent : agent) : void =
        for (L : LockedAgents, L = Agent) do return
        var IsInQueue : logic = false
        for (QueuedPlayer : Queue, QueuedPlayer = Agent):
            set IsInQueue = true
        if (IsInQueue = false):
            set Queue += array { Agent }
            if. set QueueEntryTimes[Agent] = GetSimulationElapsedTime()
            Print("[Matchmaking] Player joined queue. Total queued: {Queue.Length}.")

    MatchmakingLoop()<suspends> : void =
        loop:
            Sleep(MatchmakingCheckInterval)
            set Queue = for (Q : Queue, P := player[Q], P.IsActive[]) do Q
            if (Queue.Length >= 2, QueueSelectionWindow >= 2):
                InactiveArenas := MapManager.GetInactiveMaps()
                if (InactiveArenas.Length > 0):
                    EffectiveWindow := if (Queue.Length < QueueSelectionWindow) then Queue.Length else QueueSelectionWindow
                    if (EffectiveWindow >= 2):
                        Idx1 := GetRandomInt(0, EffectiveWindow - 1)
                        RandOffset := GetRandomInt(1, EffectiveWindow - 1)
                        if (Idx2 := Mod[Idx1 + RandOffset, EffectiveWindow]):
                            if (P1 := Queue[Idx1], P2 := Queue[Idx2], P1 <> P2):
                                ArenaIdx := GetRandomInt(0, InactiveArenas.Length - 1)
                                if (SelectedArena := InactiveArenas[ArenaIdx]):
                                    var RemainingQueue : []agent = array{}
                                    for (Idx -> QueuedPlayer : Queue):
                                        if (Idx <> Idx1, Idx <> Idx2):
                                            set RemainingQueue += array { QueuedPlayer }
                                    set Queue = RemainingQueue

                                    Print("[Matchmaking] Match found: Pairing in arena \"{SelectedArena.General.MapName}\".")
                                    MapManager.ReserveMap(SelectedArena)
                                    
                                    # Signal MatchFoundEvent for LobbyHUDManager to play 3s countdown popup
                                    LockAgents(P1, P2)
                                    MatchFoundEvent.Signal((P1, P2, SelectedArena.General.MapName, SelectedArena))
                                else set Queue += array { P1, P2 }

    GetPlayerQueuePosition<public>(Agent : agent)<transacts> : ?int =
        for (Idx -> QPlayer : Queue, QPlayer = Agent):
            return option { Idx + 1 }
        return false

    GetPlayerQueueDuration<public>(Agent : agent) : float =
        if (EntryTime := QueueEntryTimes[Agent]):
            return GetSimulationElapsedTime() - EntryTime
        return 0.0

    GetEstimatedWaitTime<public>(Agent : agent)<transacts> : float =
        if (Pos := GetPlayerQueuePosition(Agent)?):
            if (PairsAhead := Floor[(Pos * 1.0) / 2.0]):
                SafeMultiplier := if (PairsAhead > 0) then (PairsAhead * 1.0) else 1.0
                return SafeMultiplier * MatchmakingCheckInterval
        return MatchmakingCheckInterval

    GetQueueLength<public>()<transacts> : int = Queue.Length

    IsPlayerQueued<public>(Agent : agent)<transacts> : logic =
        for (QueuedPlayer : Queue, QueuedPlayer = Agent):
            return true
        return false

    EnqueuePlayer<public>(Agent : agent) : void = HandlePlayerReadyUp(Agent)

    DequeuePlayer<public>(Agent : agent) : void =
        set Queue = for (QueuedPlayer : Queue, QueuedPlayer <> Agent) do QueuedPlayer
        var NewEntryTimes : [agent]float = map{}
        for (Key -> Val : QueueEntryTimes, Key <> Agent):
            if. set NewEntryTimes[Key] = Val
        set QueueEntryTimes = NewEntryTimes
        Print("[Matchmaking] Player removed from queue. Total queued: {Queue.Length}.")