using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }

shop_manager := class(creative_device):
    @editable:
        ToolTip := EconomyManagerInfo
    EconomyManager : economy_manager = economy_manager{}

    @editable:
        ToolTip := CustomizationManagerInfo
    CustomizationManager : customization_manager = customization_manager{}

    @editable:
        ToolTip := PurchaseSuccessSFXInfo
    PurchaseSuccessSFX : audio_player_device = audio_player_device{}

    ShopRefreshedEvent<public> : event() = event(){}

    var CachedDailyCycleId : int = -1
    var CachedDailyItems : []customization_item_def = array{}
    var CachedWeeklyCycleId : int = -1
    var CachedFeaturedBundleTemplate : ?featured_bundle_data = false

    GetDailyCycleId()<transacts> : int =
        EpochSeconds := GetSecondsSinceEpoch()
        if (Day := Floor[EpochSeconds / 86400.0]) then return Day
        return 0

    GetWeeklyCycleId()<transacts> : int =
        EpochSeconds := GetSecondsSinceEpoch()
        if (Week := Floor[EpochSeconds / 604800.0]) then return Week
        return 0

    GetDailySecondsRemaining<public>()<transacts> : float =
        EpochSeconds := GetSecondsSinceEpoch()
        if (ElapsedToday := Mod[Floor[EpochSeconds], 86400]):
            return (86400 - ElapsedToday) * 1.0
        return 86400.0

    GetWeeklySecondsRemaining<public>()<transacts> : float =
        EpochSeconds := GetSecondsSinceEpoch()
        if (ElapsedThisWeek := Mod[Floor[EpochSeconds], 604800]):
            return (604800 - ElapsedThisWeek) * 1.0
        return 604800.0

    GeneratePseudoRandomInt(Seed : int, MinValue : int, MaxValue : int)<transacts> : tuple(int, int) =
        Range := (MaxValue - MinValue) + 1
        if (Range <= 0):
            return (MinValue, Seed)
        var NextSeed : int = Seed
        if (CalculatedSeed := Mod[Abs(Seed * 1103515245 + 12345), 2147483647]):
            set NextSeed = CalculatedSeed
        if (RandomVal := Mod[Abs(NextSeed), Range]):
            return (MinValue + RandomVal, NextSeed)
        return (MinValue, NextSeed)

    # --- 8-Item Daily Shop Generator ---
    GetDailyShopItems<public>(Agent : agent) : []shop_slot_item =
        CurrentDay := GetDailyCycleId()

        # Recompute only when day cycle changes
        if (CachedDailyCycleId <> CurrentDay or CachedDailyItems.Length = 0):
            Catalog := CustomizationManager.GetMasterCatalog()
            PrevDay := CurrentDay - 1

            var PrevSeed : int = PrevDay * 97 + 13
            var PrevDayIds : []string = array{}
            for (I := 1..8):
                Res := GeneratePseudoRandomInt(PrevSeed, 0, Catalog.Length - 1)
                set PrevSeed = Res(1)
                if (Chosen := Catalog[Res(0)]):
                    set PrevDayIds += array{ Chosen.Id }

            var Candidates : []customization_item_def = array{}
            for (Item : Catalog):
                var InPrev : logic = false
                for (PId : PrevDayIds, PId = Item.Id) do set InPrev = true
                if (not InPrev? or Catalog.Length <= 8):
                    set Candidates += array{ Item }

            var PoolToUse : []customization_item_def = if (Candidates.Length >= 8) then Candidates else Catalog
            var DaySeed : int = CurrentDay * 97 + 13
            var SelectedItems : []customization_item_def = array{}

            for (I := 1..8):
                if (PoolToUse.Length > 0):
                    Res := GeneratePseudoRandomInt(DaySeed, 0, PoolToUse.Length - 1)
                    set DaySeed = Res(1)
                    if (Item := PoolToUse[Res(0)]):
                        set SelectedItems += array{ Item }
                        set PoolToUse = for (Idx -> Candidate : PoolToUse, Idx <> Res(0)) do Candidate

            set CachedDailyCycleId = CurrentDay
            set CachedDailyItems = SelectedItems

        # Map ownership status for the viewing player
        DailySlots := for (Item : CachedDailyItems):
            IsUnlocked := CustomizationManager.IsItemUnlocked(Agent, Item.Id)
            shop_slot_item:
                Def := Item
                DiscountPercent := 0
                FinalPrice := Item.BasePrice
                IsPurchased := IsUnlocked
                IsFeatured := false

        return DailySlots
        
    # --- 5-Item Weekly Featured Bundle (Prorated Pricing & Per-Slot Ownership Flags) ---
    GetWeeklyFeaturedBundle<public>(Agent : agent) : ?featured_bundle_data =
        CurrentWeek := GetWeeklyCycleId()

        # Recompute bundle template only when week cycle changes
        if (CachedWeeklyCycleId <> CurrentWeek or not CachedFeaturedBundleTemplate?):
            Catalog := CustomizationManager.GetMasterCatalog()

            var Backpacks : []customization_item_def = array{}
            var KillEffects : []customization_item_def = array{}
            var Emblems : []customization_item_def = array{}
            var Backplates : []customization_item_def = array{}
            var Titles : []customization_item_def = array{}

            for (Item : Catalog):
                case (Item.Type):
                    customization_type.Backpack => set Backpacks += array{ Item }
                    customization_type.KillEffect => set KillEffects += array{ Item }
                    customization_type.Emblem => set Emblems += array{ Item }
                    customization_type.Backplate => set Backplates += array{ Item }
                    customization_type.Title => set Titles += array{ Item }

            if (Backpacks.Length = 0 or KillEffects.Length = 0 or Emblems.Length = 0 or Backplates.Length = 0 or Titles.Length = 0):
                return false

            var Seed : int = CurrentWeek * 101 + 17

            ResBP := GeneratePseudoRandomInt(Seed, 0, Backpacks.Length - 1)
            set Seed = ResBP(1)
            ItemBP := if (B := Backpacks[ResBP(0)]) then B else customization_item_def{}

            ResKE := GeneratePseudoRandomInt(Seed, 0, KillEffects.Length - 1)
            set Seed = ResKE(1)
            ItemKE := if (K := KillEffects[ResKE(0)]) then K else customization_item_def{}

            ResEM := GeneratePseudoRandomInt(Seed, 0, Emblems.Length - 1)
            set Seed = ResEM(1)
            ItemEM := if (E := Emblems[ResEM(0)]) then E else customization_item_def{}

            ResBK := GeneratePseudoRandomInt(Seed, 0, Backplates.Length - 1)
            set Seed = ResBK(1)
            ItemBK := if (Bk := Backplates[ResBK(0)]) then Bk else customization_item_def{}

            ResTI := GeneratePseudoRandomInt(Seed, 0, Titles.Length - 1)
            set Seed = ResTI(1)
            ItemTI := if (T := Titles[ResTI(0)]) then T else customization_item_def{}

            DiscountRes := GeneratePseudoRandomInt(Seed, 10, 20)
            DiscountPct := DiscountRes(0)
            TotalOriginal := ItemBP.BasePrice + ItemKE.BasePrice + ItemEM.BasePrice + ItemBK.BasePrice + ItemTI.BasePrice

            Template := featured_bundle_data:
                BundleName := "FEATURED BUNDLE"
                BackpackItem := ItemBP
                KillEffectItem := ItemKE
                EmblemItem := ItemEM
                BackplateItem := ItemBK
                TitleItem := ItemTI
                OriginalPrice := TotalOriginal
                DiscountPercent := DiscountPct
                IsValid := true

            set CachedWeeklyCycleId = CurrentWeek
            set CachedFeaturedBundleTemplate = option { Template }

        if (Bundle := CachedFeaturedBundleTemplate?):
            Owned1 := CustomizationManager.IsItemUnlocked(Agent, Bundle.BackpackItem.Id)
            Owned2 := CustomizationManager.IsItemUnlocked(Agent, Bundle.KillEffectItem.Id)
            Owned3 := CustomizationManager.IsItemUnlocked(Agent, Bundle.EmblemItem.Id)
            Owned4 := CustomizationManager.IsItemUnlocked(Agent, Bundle.BackplateItem.Id)
            Owned5 := CustomizationManager.IsItemUnlocked(Agent, Bundle.TitleItem.Id)

            var UnownedSubtotal : int = 0
            if (not Owned1?): 
                set UnownedSubtotal += Bundle.BackpackItem.BasePrice
            if (not Owned2?): 
                set UnownedSubtotal += Bundle.KillEffectItem.BasePrice
            if (not Owned3?): 
                set UnownedSubtotal += Bundle.EmblemItem.BasePrice
            if (not Owned4?): 
                set UnownedSubtotal += Bundle.BackplateItem.BasePrice
            if (not Owned5?): 
                set UnownedSubtotal += Bundle.TitleItem.BasePrice

            DiscountAmount := if (DA := Round[(UnownedSubtotal * 1.0) * ((Bundle.DiscountPercent * 1.0) / 100.0)]) then DA else 0
            ProratedPrice := if (UnownedSubtotal > 0) then (UnownedSubtotal - DiscountAmount) else 0
            IsAllOwned := if (Owned1? and Owned2? and Owned3? and Owned4? and Owned5?) then true else false

            return option { featured_bundle_data:
                BundleName := Bundle.BundleName
                BackpackItem := Bundle.BackpackItem
                KillEffectItem := Bundle.KillEffectItem
                EmblemItem := Bundle.EmblemItem
                BackplateItem := Bundle.BackplateItem
                TitleItem := Bundle.TitleItem
                OriginalPrice := Bundle.OriginalPrice
                UnownedOriginalPrice := UnownedSubtotal
                DiscountPercent := Bundle.DiscountPercent
                FinalPrice := ProratedPrice
                Slot1Owned := Owned1
                Slot2Owned := Owned2
                Slot3Owned := Owned3
                Slot4Owned := Owned4
                Slot5Owned := Owned5
                IsPurchased := IsAllOwned
                IsValid := true
            }
        return false
    # --- Purchase Featured Bundle (Unlocks All Unowned Items) ---
    PurchaseFeaturedBundle<public>(Agent : agent) : logic =
        GetBundle := GetWeeklyFeaturedBundle(Agent)
        if (Bundle := GetBundle?):
            if (Bundle.IsPurchased?):
                Print("[ShopManager] Featured Bundle is already fully owned.")
                return false

            PriceToCharge := Bundle.FinalPrice
            if (PriceToCharge > 0):
                Success := EconomyManager.DebitCybercash(Agent, PriceToCharge)
                if (Success?):
                    # Unlock all unowned items in the bundle
                    if (not Bundle.Slot1Owned?):
                        CustomizationManager.UnlockItem(Agent, Bundle.BackpackItem.Id)
                    if (not Bundle.Slot2Owned?):
                        CustomizationManager.UnlockItem(Agent, Bundle.KillEffectItem.Id)
                    if (not Bundle.Slot3Owned?):
                        CustomizationManager.UnlockItem(Agent, Bundle.EmblemItem.Id)
                    if (not Bundle.Slot4Owned?):
                        CustomizationManager.UnlockItem(Agent, Bundle.BackplateItem.Id)
                    if (not Bundle.Slot5Owned?):
                        CustomizationManager.UnlockItem(Agent, Bundle.TitleItem.Id)

                    PurchaseSuccessSFX.Play(Agent)
                    Print("[ShopManager] Successfully purchased Featured Bundle for {PriceToCharge} Cybercash.")
                    return true
                else:
                    Print("[ShopManager] Insufficient Cybercash for Featured Bundle.")
                    return false
        return false

    # --- Daily Single-Item Purchase Verification ---
    PurchaseShopItem<public>(Agent : agent, ItemId : string) : logic =
        if (CustomizationManager.IsItemUnlocked(Agent, ItemId)?):
            Print("[ShopManager] Item already owned.")
            return false

        if (Def := CustomizationManager.FindItemDef(ItemId)?):
            Price := Def.BasePrice
            Success := EconomyManager.DebitCybercash(Agent, Price)
            if (Success?):
                CustomizationManager.UnlockItem(Agent, ItemId)
                PurchaseSuccessSFX.Play(Agent)
                Print("[ShopManager] Successfully bought {Def.Name} for {Price} Cybercash.")
                return true
            else Print("[ShopManager] Insufficient Cybercash balance for {Def.Name}.")
        return false