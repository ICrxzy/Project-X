using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Verse.org/Random }

loadout_blitz_settings := class<concrete>():
    @editable:
        ToolTip := BlitzPoolInfo
    BlitzLoadoutPool : []blitz_loadout_data = array{}

loadout_manager := class(creative_device):
    @editable:
        ToolTip := ItemRemoverInfo
    ItemRemover : item_remover_device = item_remover_device{}

    @editable:
        ToolTip := GrantDelayInfo
    GrantDelay : float = 0.1

    @editable:
        ToolTip := BlitzPoolInfo
    BlitzSettings : loadout_blitz_settings = loadout_blitz_settings{}

    GrantMatchLoadout<public>(P1 : agent, P2 : agent, LoadoutIndex : int)<suspends> : void =
        ItemRemover.Remove(P1)
        ItemRemover.Remove(P2)
        Sleep(GrantDelay)
        HandleBlitzGrant(P1, P2, LoadoutIndex)

    HandleBlitzGrant(P1 : agent, P2 : agent, LoadoutIndex : int) : void =
        PoolSize := BlitzSettings.BlitzLoadoutPool.Length
        if (PoolSize > 0):
            SafeIndex := if (LoadoutIndex >= 0 and LoadoutIndex < PoolSize) then LoadoutIndex else 0
            if (Loadout := BlitzSettings.BlitzLoadoutPool[SafeIndex]):
                Loadout.PrimaryGranter.CycleToRandomItem(P1)
                Loadout.SpecialGranter.CycleToRandomItem(P1)
                Loadout.UtilityGranter.CycleToRandomItem(P1)

                Loadout.PrimaryGranter.GrantItem(P2)
                Loadout.SpecialGranter.GrantItem(P2)
                Loadout.UtilityGranter.GrantItem(P2)