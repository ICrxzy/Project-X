using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }

map_manager := class(creative_device):
    @editable:
        ToolTip := ArenaListInfo
    Arenas : []arena_map = array{}

    OnBegin<override>()<suspends> : void =
        Print("[MapManager] Validating and initializing {Arenas.Length} configured arenas...")
        var ValidCount : int = 0
        for (Idx -> Map : Arenas):
            set Map.Status = map_status.Inactive
            set Map.CooldownGeneration = 0
            set ValidCount += 1
            Print("[MapManager] Arena [{Idx + 1}/{Arenas.Length}] CONFIGURED: \"{Map.General.MapName}\".")
        Print("[MapManager] Initialization complete: {ValidCount}/{Arenas.Length} arenas active and eligible for matchmaking.")

    GetInactiveMaps<public>() : []arena_map =
        for (Map : Arenas, Map.Status = map_status.Inactive) do Map

    ReserveMap<public>(Map : arena_map) : void =
        set Map.CooldownGeneration += 1
        set Map.Status = map_status.Pending
        Print("[MapManager] Reserved arena: \"{Map.General.MapName}\" (Status: Pending).")

    ActivateMap<public>(Map : arena_map) : void =
        set Map.Status = map_status.Active
        Print("[MapManager] Activated arena: \"{Map.General.MapName}\" (Status: Active).")

    ReleaseMap<public>(Map : arena_map, Cooldown : float) : void =
        set Map.CooldownGeneration += 1
        set Map.Status = map_status.Pending
        LocalGeneration := Map.CooldownGeneration
        Print("[MapManager] Released arena: \"{Map.General.MapName}\" (Status: Pending, Cooldown: {Cooldown}s).")
        spawn { FinishArenaCooldown(Map, LocalGeneration, Cooldown) }

    FinishArenaCooldown(Map : arena_map, Generation : int, Cooldown : float)<suspends> : void =
        Sleep(Cooldown)
        if (Map.CooldownGeneration = Generation, Map.Status = map_status.Pending):
            set Map.Status = map_status.Inactive
            Print("[MapManager] Arena cooldown complete: \"{Map.General.MapName}\" (Status: Inactive).")

    GetTotalArenasCount<public>()<transacts> : int = Arenas.Length
    ResolveControllerForMap<public>(Map : arena_map) : arena_controller = Map.LogicDevices.Controller