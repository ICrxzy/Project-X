using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }

customization_manager := class(creative_device):
    @editable:
        ToolTip := StatsManagerInfo
    StatsManager : stats_manager = stats_manager{}

    @editable:
        ToolTip := BackpackVfxPowerupInfo
    BackpackVfxPowerups : []visual_effect_powerup_device = array{}

    # Blueprint creative prop assets for Kill Effects
    @editable:
        ToolTip := KillEffectPropAssetInfo
    KillEffectPropAssets : []creative_prop_asset = array{}

    # Default fallback Kill Effect prop asset
    @editable
    DefaultKillEffectProp : creative_prop_asset = DefaultCreativePropAsset

    # Testing toggle: Unlocks all 44 items automatically in play sessions
    @editable
    UnlockAllForTesting : logic = true

    var PlayerCustomizationMap : [agent]player_persistable_customization = map{}
    var PlayerCarouselPageMap : [agent][customization_type]int = map{}

    CustomizationUpdatedEvent<public> : event(agent) = event(agent){}

    OnBegin<override>()<suspends> : void =
        GetPlayspace().PlayerAddedEvent().Subscribe(InitializePlayerCustomization)
        GetPlayspace().PlayerRemovedEvent().Subscribe(OnPlayerRemoved)
        for (P : GetPlayspace().GetPlayers()) do InitializePlayerCustomization(P)

    # Safe lazy-initialization helper preventing race conditions on startup
    GetOrInitializePlayerCustomization<public>(Agent : agent) : player_persistable_customization =
        if (Data := PlayerCustomizationMap[Agent]):
            return Data
        InitializePlayerCustomization(Agent)
        if (Data := PlayerCustomizationMap[Agent]):
            return Data
        return player_persistable_customization{}

    InitializePlayerCustomization<public>(Agent : agent) : void =
        if (Plr := player[Agent]):
            Profile := GetPlayerProfile(Plr)
            var LoadedData : player_persistable_customization = Profile.Customization

            # Collect all default unlocked items
            var DefaultUnlockedIds : []string = array{}
            for (Item : GetMasterCatalog(), Item.IsDefaultUnlocked?):
                set DefaultUnlockedIds += array{ Item.Id }

            # If testing toggle is enabled, unlock everything in catalog
            var MergedUnlocked : []string = if (UnlockAllForTesting?) then (for (Item : GetMasterCatalog()) do Item.Id) else LoadedData.UnlockedItemIds

            if (not UnlockAllForTesting?):
                for (DefId : DefaultUnlockedIds):
                    var AlreadyHas : logic = false
                    for (OwnedId : MergedUnlocked, OwnedId = DefId):
                        set AlreadyHas = true
                    if (not AlreadyHas?):
                        set MergedUnlocked += array{ DefId }

            EquippedBP := if (LoadedData.EquippedBackpackId <> "") then LoadedData.EquippedBackpackId else "BP 1"
            EquippedKE := if (LoadedData.EquippedKillEffectId <> "") then LoadedData.EquippedKillEffectId else "KE 1"
            EquippedEM := if (LoadedData.EquippedEmblemId <> "") then LoadedData.EquippedEmblemId else "EM 2"
            EquippedBK := if (LoadedData.EquippedBackplateId <> "") then LoadedData.EquippedBackplateId else "CC 1"
            EquippedTI := if (LoadedData.EquippedTitleId <> "") then LoadedData.EquippedTitleId else "Cracked"

            UpdatedData := player_persistable_customization:
                UnlockedItemIds := MergedUnlocked
                EquippedBackpackId := EquippedBP
                EquippedKillEffectId := EquippedKE
                EquippedEmblemId := EquippedEM
                EquippedBackplateId := EquippedBK
                EquippedTitleId := EquippedTI
                ShowRankOnCard := LoadedData.ShowRankOnCard

            if. set PlayerCustomizationMap[Agent] = UpdatedData
            SavePlayerCustomization(Plr)

            # Ensure page map has all 5 categories initialized
            if (not PlayerCarouselPageMap[Agent]):
                if. set PlayerCarouselPageMap[Agent] = map{
                    customization_type.Backpack => 0,
                    customization_type.KillEffect => 0,
                    customization_type.Emblem => 0,
                    customization_type.Backplate => 0,
                    customization_type.Title => 0
                }

    OnPlayerRemoved(P : player) : void =
        SavePlayerCustomization(P)
        var NewMap : [agent]player_persistable_customization = map{}
        for (Key -> Val : PlayerCustomizationMap, Key <> P):
            if. set NewMap[Key] = Val
        set PlayerCustomizationMap = NewMap

        var NewPageMap : [agent][customization_type]int = map{}
        for (Key -> Val : PlayerCarouselPageMap, Key <> P):
            if. set NewPageMap[Key] = Val
        set PlayerCarouselPageMap = NewPageMap

    SavePlayerCustomization(Plr : player) : void =
        if (Data := PlayerCustomizationMap[Plr]):
            SavePlayerCustomizationToProfile(Plr, Data)

    # --- Master Cosmetic Catalog (44 Total Items) ---
    GetMasterCatalog<public>()<transacts> : []customization_item_def =
        array:
            # Backpacks
            customization_item_def{ Id := "BP 1", Type := customization_type.Backpack, Tier := customization_tier.Tier1, Name := "Standard Rig", BasePrice := 500, Thumbnail := UI.Unranked, VfxIndex := 0, IsDefaultUnlocked := true },
            customization_item_def{ Id := "BP 2", Type := customization_type.Backpack, Tier := customization_tier.Tier1, Name := "Commando Pack", BasePrice := 500, Thumbnail := UI.Unranked, VfxIndex := 1 },
            customization_item_def{ Id := "BP 3", Type := customization_type.Backpack, Tier := customization_tier.Tier1, Name := "SO-COMM Pack", BasePrice := 500, Thumbnail := UI.Unranked, VfxIndex := 2 },
            customization_item_def{ Id := "BP 4", Type := customization_type.Backpack, Tier := customization_tier.Tier1, Name := "Medical Stachel", BasePrice := 500, Thumbnail := UI.Unranked, VfxIndex := 3 },
            customization_item_def{ Id := "BP 5", Type := customization_type.Backpack, Tier := customization_tier.Tier1, Name := "Bloodbane", BasePrice := 500, Thumbnail := UI.Unranked, VfxIndex := 4 },

            # Kill Effects (Frag Effects)
            customization_item_def{ Id := "KE 1", Type := customization_type.KillEffect, Tier := customization_tier.Tier1, Name := "Neutral Disruption", BasePrice := 500, IsDefaultUnlocked := true },
            customization_item_def{ Id := "KE 2", Type := customization_type.KillEffect, Tier := customization_tier.Tier1, Name := "Disco Jam", BasePrice := 500 },
            customization_item_def{ Id := "KE 3", Type := customization_type.KillEffect, Tier := customization_tier.Tier1, Name := "Melting Madness", BasePrice := 500 },
            customization_item_def{ Id := "KE 4", Type := customization_type.KillEffect, Tier := customization_tier.Tier1, Name := "Disruption", BasePrice := 500 },
            customization_item_def{ Id := "KE 5", Type := customization_type.KillEffect, Tier := customization_tier.Tier1, Name := "Displacement", BasePrice := 500 },

            # Emblems
            customization_item_def{ Id := "EM 1", Type := customization_type.Emblem, Tier := customization_tier.Tier4, Name := "Developer's Crest", BasePrice := 0, Thumbnail := UI.S5V2 },
            customization_item_def{ Id := "EM 2", Type := customization_type.Emblem, Tier := customization_tier.Tier1, Name := "Recruit", BasePrice := 200, Thumbnail := UI.level, IsDefaultUnlocked := true },
            customization_item_def{ Id := "EM 3", Type := customization_type.Emblem, Tier := customization_tier.Tier1, Name := "Explosion", BasePrice := 200, Thumbnail := UI.Explosion },
            customization_item_def{ Id := "EM 4", Type := customization_type.Emblem, Tier := customization_tier.Tier1, Name := "By The Horns", BasePrice := 200, Thumbnail := UI.ByTheHorn },
            customization_item_def{ Id := "EM 5", Type := customization_type.Emblem, Tier := customization_tier.Tier1, Name := "Mr. Monkee", BasePrice := 200, Thumbnail := UI.Cool_Monkey },
            customization_item_def{ Id := "EM 6", Type := customization_type.Emblem, Tier := customization_tier.Tier1, Name := "Who's da bomb?", BasePrice := 200, Thumbnail := UI.DaBomb },
            customization_item_def{ Id := "EM 7", Type := customization_type.Emblem, Tier := customization_tier.Tier1, Name := "Disco Baller", BasePrice := 200, Thumbnail := UI.DiscoBaller },
            customization_item_def{ Id := "EM 8", Type := customization_type.Emblem, Tier := customization_tier.Tier1, Name := "Dragon Spirit", BasePrice := 200, Thumbnail := UI.DragonSpirit },
            customization_item_def{ Id := "EM 9", Type := customization_type.Emblem, Tier := customization_tier.Tier1, Name := "Drum Beat", BasePrice := 200, Thumbnail := UI.DrumBeat },
            customization_item_def{ Id := "EM 10", Type := customization_type.Emblem, Tier := customization_tier.Tier1, Name := "Eyes Wide Open", BasePrice := 200, Thumbnail := UI.EyesOpen },
            customization_item_def{ Id := "EM 11", Type := customization_type.Emblem, Tier := customization_tier.Tier1, Name := "Fish Paste", BasePrice := 200, Thumbnail := UI.FishPaste },
            customization_item_def{ Id := "EM 12", Type := customization_type.Emblem, Tier := customization_tier.Tier1, Name := "G.O.A.T", BasePrice := 200, Thumbnail := UI.Goat },
            customization_item_def{ Id := "EM 13", Type := customization_type.Emblem, Tier := customization_tier.Tier1, Name := "King Krab", BasePrice := 200, Thumbnail := UI.KingKrab },
            customization_item_def{ Id := "EM 14", Type := customization_type.Emblem, Tier := customization_tier.Tier1, Name := "Love Tap", BasePrice := 200, Thumbnail := UI.LoveTap },
            customization_item_def{ Id := "EM 15", Type := customization_type.Emblem, Tier := customization_tier.Tier1, Name := "We live in a society...", BasePrice := 200, Thumbnail := UI.Society },
            customization_item_def{ Id := "EM 16", Type := customization_type.Emblem, Tier := customization_tier.Tier1, Name := "Thirst Quencher", BasePrice := 200, Thumbnail := UI.ThirstQuencher },
            customization_item_def{ Id := "EM 17", Type := customization_type.Emblem, Tier := customization_tier.Tier1, Name := "According to avaiation...", BasePrice := 200, Thumbnail := UI.TrioBees },

            # Calling Cards (Backplates)
            customization_item_def{ Id := "CC 1", Type := customization_type.Backplate, Tier := customization_tier.Tier1, Name := "Recruit", BasePrice := 0, Thumbnail := UI.CC_Default, IsDefaultUnlocked := true },
            customization_item_def{ Id := "CC 2", Type := customization_type.Backplate, Tier := customization_tier.Tier1, Name := "New Additions", BasePrice := 200, Thumbnail := UI.CC_PlusSigns },
            customization_item_def{ Id := "CC 3", Type := customization_type.Backplate, Tier := customization_tier.Tier1, Name := "Private", BasePrice := 200, Thumbnail := UI.Amatuer },
            customization_item_def{ Id := "CC 4", Type := customization_type.Backplate, Tier := customization_tier.Tier2, Name := "Aura Wave", BasePrice := 500, Thumbnail := UI.AuraWave },
            customization_item_def{ Id := "CC 5", Type := customization_type.Backplate, Tier := customization_tier.Tier1, Name := "Bright Skies", BasePrice := 200, Thumbnail := UI.BrightSkies },
            customization_item_def{ Id := "CC 6", Type := customization_type.Backplate, Tier := customization_tier.Tier2, Name := "Bubblegum", BasePrice := 500, Thumbnail := UI.Bubblegum },
            customization_item_def{ Id := "CC 7", Type := customization_type.Backplate, Tier := customization_tier.Tier3, Name := "Code Red", BasePrice := 800, Thumbnail := UI.CodeRed },
            customization_item_def{ Id := "CC 8", Type := customization_type.Backplate, Tier := customization_tier.Tier1, Name := "Droplets", BasePrice := 200, Thumbnail := UI.Droplets },
            customization_item_def{ Id := "CC 9", Type := customization_type.Backplate, Tier := customization_tier.Tier2, Name := "Ember Forest", BasePrice := 500, Thumbnail := UI.EmberForest },
            customization_item_def{ Id := "CC 10", Type := customization_type.Backplate, Tier := customization_tier.Tier1, Name := "Geometric", BasePrice := 200, Thumbnail := UI.Geometric },
            customization_item_def{ Id := "CC 11", Type := customization_type.Backplate, Tier := customization_tier.Tier2, Name := "Glacial", BasePrice := 500, Thumbnail := UI.Glacial },
            customization_item_def{ Id := "CC 12", Type := customization_type.Backplate, Tier := customization_tier.Tier1, Name := "International", BasePrice := 200, Thumbnail := UI.International },
            customization_item_def{ Id := "CC 13", Type := customization_type.Backplate, Tier := customization_tier.Tier2, Name := "Mirage", BasePrice := 500, Thumbnail := UI.Mirage },

            # Titles
            customization_item_def{ Id := "Cracked", Type := customization_type.Title, Tier := customization_tier.Tier1, Name := "Cracked Title", BasePrice := 200, TitleText := "Cracked", IsDefaultUnlocked := true },
            customization_item_def{ Id := "G.O.A.T", Type := customization_type.Title, Tier := customization_tier.Tier2, Name := "G.O.A.T Title", BasePrice := 500, TitleText := "G.O.A.T" },
            customization_item_def{ Id := "Nightmare", Type := customization_type.Title, Tier := customization_tier.Tier1, Name := "Nightmare Title", BasePrice := 200, TitleText := "Nightmare" },
            customization_item_def{ Id := "Mercenary", Type := customization_type.Title, Tier := customization_tier.Tier1, Name := "Mercenary Title", BasePrice := 200, TitleText := "Mercenary" },
            customization_item_def{ Id := "Marksman", Type := customization_type.Title, Tier := customization_tier.Tier1, Name := "Marksman Title", BasePrice := 200, TitleText := "Marksman" },
            customization_item_def{ Id := "Bulletproof", Type := customization_type.Title, Tier := customization_tier.Tier2, Name := "Bulletproof Title", BasePrice := 500, TitleText := "Bulletproof" },
            customization_item_def{ Id := "One Man Army", Type := customization_type.Title, Tier := customization_tier.Tier2, Name := "One Man Army Title", BasePrice := 500, TitleText := "One Man Army" },
            customization_item_def{ Id := "War Dog", Type := customization_type.Title, Tier := customization_tier.Tier1, Name := "War Dog Title", BasePrice := 200, TitleText := "War Dog" },
            customization_item_def{ Id := "Bullet Sponge", Type := customization_type.Title, Tier := customization_tier.Tier1, Name := "Bullet Sponge Title", BasePrice := 200, TitleText := "Bullet Sponge" },
            customization_item_def{ Id := "Unkillable", Type := customization_type.Title, Tier := customization_tier.Tier2, Name := "Unkillable Title", BasePrice := 500, TitleText := "Unkillable" }

    # --- Live Player Card Data Resolution ---
    GetPlayerCardData<public>(Agent : agent) : player_card_data =
        GetOrInitializePlayerCustomization(Agent)
        EmblemId := GetEquippedItemId(Agent, customization_type.Emblem)
        EmblemThumb := if (Def := FindItemDef(EmblemId)?) then Def.Thumbnail else UI.level

        BackplateId := GetEquippedItemId(Agent, customization_type.Backplate)
        BackplateThumb := if (Def := FindItemDef(BackplateId)?) then Def.Thumbnail else UI.CC_Default

        TitleId := GetEquippedItemId(Agent, customization_type.Title)
        TitleStr := if (Def := FindItemDef(TitleId)?) then Def.TitleText else ""

        RankInfo := if (Stats := StatsManager.GetPlayerStats(Agent)?) then StatsManager.ResolveRankFromElo(Stats.Elo) else rank_resolution{ Tier := 0, RankName := "Unranked", RankIcon := UI.Unranked }
        ShowRankPref := GetShowRankPreference(Agent)

        return player_card_data:
            PlayerName := "Player"
            EmblemThumbnail := EmblemThumb
            BackplateThumbnail := BackplateThumb
            TitleText := TitleStr
            RankName := RankInfo.RankName
            RankIcon := RankInfo.RankIcon
            ShowRank := ShowRankPref
            IsValid := true

    DevUnlockAllCosmetics<public>(Agent : agent) : void =
        if (Plr := player[Agent]):
            Data := GetOrInitializePlayerCustomization(Agent)
            AllCatalogIds := for (Item : GetMasterCatalog()) do Item.Id
            Updated := player_persistable_customization:
                UnlockedItemIds := AllCatalogIds
                EquippedBackpackId := Data.EquippedBackpackId
                EquippedKillEffectId := Data.EquippedKillEffectId
                EquippedEmblemId := Data.EquippedEmblemId
                EquippedBackplateId := Data.EquippedBackplateId
                EquippedTitleId := Data.EquippedTitleId
                ShowRankOnCard := Data.ShowRankOnCard
            if. set PlayerCustomizationMap[Agent] = Updated
            SavePlayerCustomization(Plr)
            CustomizationUpdatedEvent.Signal(Agent)
            Print("[CustomizationManager] DEV: Unlocked all {AllCatalogIds.Length} cosmetics for player.")

    FindItemDef<public>(ItemId : string)<transacts> : ?customization_item_def =
        for (Item : GetMasterCatalog(), Item.Id = ItemId):
            return option { Item }
        return false

    IsItemUnlocked<public>(Agent : agent, ItemId : string)<transacts> : logic =
        if (UnlockAllForTesting?):
            return true
        if (Data := PlayerCustomizationMap[Agent]):
            for (UnlockedId : Data.UnlockedItemIds, UnlockedId = ItemId):
                return true
        return false

    UnlockItem<public>(Agent : agent, ItemId : string) : void =
        if (Plr := player[Agent]):
            Data := GetOrInitializePlayerCustomization(Agent)
            if (not IsItemUnlocked(Agent, ItemId)?):
                Updated := player_persistable_customization:
                    UnlockedItemIds := Data.UnlockedItemIds + array{ ItemId }
                    EquippedBackpackId := Data.EquippedBackpackId
                    EquippedKillEffectId := Data.EquippedKillEffectId
                    EquippedEmblemId := Data.EquippedEmblemId
                    EquippedBackplateId := Data.EquippedBackplateId
                    EquippedTitleId := Data.EquippedTitleId
                    ShowRankOnCard := Data.ShowRankOnCard
                if. set PlayerCustomizationMap[Agent] = Updated
                SavePlayerCustomization(Plr)
                CustomizationUpdatedEvent.Signal(Agent)
                Print("[CustomizationManager] Unlocked cosmetic: {ItemId} for player.")

    GetEquippedItemId<public>(Agent : agent, Category : customization_type)<transacts> : string =
        if (Data := PlayerCustomizationMap[Agent]):
            case (Category):
                customization_type.Backpack => Data.EquippedBackpackId
                customization_type.KillEffect => Data.EquippedKillEffectId
                customization_type.Emblem => Data.EquippedEmblemId
                customization_type.Backplate => Data.EquippedBackplateId
                customization_type.Title => Data.EquippedTitleId
        else:
            case (Category):
                customization_type.Backpack => "BP 1"
                customization_type.KillEffect => "KE 1"
                customization_type.Emblem => "EM 2"
                customization_type.Backplate => "CC 1"
                customization_type.Title => "Cracked"

    EquipItem<public>(Agent : agent, ItemId : string) : logic =
        Data := GetOrInitializePlayerCustomization(Agent)
        if (Def := FindItemDef(ItemId)?):
            if (UnlockAllForTesting? or IsItemUnlocked(Agent, ItemId)?):
                NewBackpack := if (Def.Type = customization_type.Backpack) then ItemId else Data.EquippedBackpackId
                NewKillEffect := if (Def.Type = customization_type.KillEffect) then ItemId else Data.EquippedKillEffectId
                NewEmblem := if (Def.Type = customization_type.Emblem) then ItemId else Data.EquippedEmblemId
                NewBackplate := if (Def.Type = customization_type.Backplate) then ItemId else Data.EquippedBackplateId
                NewTitle := if (Def.Type = customization_type.Title) then ItemId else Data.EquippedTitleId

                Updated := player_persistable_customization:
                    UnlockedItemIds := Data.UnlockedItemIds
                    EquippedBackpackId := NewBackpack
                    EquippedKillEffectId := NewKillEffect
                    EquippedEmblemId := NewEmblem
                    EquippedBackplateId := NewBackplate
                    EquippedTitleId := NewTitle
                    ShowRankOnCard := Data.ShowRankOnCard

                if. set PlayerCustomizationMap[Agent] = Updated
                if (Plr := player[Agent]):
                    SavePlayerCustomization(Plr)

                if (Def.Type = customization_type.Backpack):
                    ApplyEquippedBackpackVfx(Agent)

                CustomizationUpdatedEvent.Signal(Agent)
                Print("[CustomizationManager] Equipped cosmetic: {ItemId}.")
                return true
        return false

    ToggleRankVisibility<public>(Agent : agent) : logic =
        if (Plr := player[Agent]):
            Data := GetOrInitializePlayerCustomization(Agent)
            NewState := if (Data.ShowRankOnCard?) then false else true
            Updated := player_persistable_customization:
                UnlockedItemIds := Data.UnlockedItemIds
                EquippedBackpackId := Data.EquippedBackpackId
                EquippedKillEffectId := Data.EquippedKillEffectId
                EquippedEmblemId := Data.EquippedEmblemId
                EquippedBackplateId := Data.EquippedBackplateId
                EquippedTitleId := Data.EquippedTitleId
                ShowRankOnCard := NewState
            if. set PlayerCustomizationMap[Agent] = Updated
            SavePlayerCustomization(Plr)
            CustomizationUpdatedEvent.Signal(Agent)
            return NewState
        return true

    GetShowRankPreference<public>(Agent : agent)<transacts> : logic =
        if (Data := PlayerCustomizationMap[Agent]):
            return Data.ShowRankOnCard
        return true

    # --- Page State Helpers for 5 Rows ---
    GetPlayerPage(Agent : agent, Category : customization_type) : int =
        if (CategoryMap := PlayerCarouselPageMap[Agent], P := CategoryMap[Category]) then P else 0

    SetPlayerPage(Agent : agent, Category : customization_type, NewPage : int) : void =
        var CategoryMap : [customization_type]int = if (CM := PlayerCarouselPageMap[Agent]) then CM else map{}
        if. set CategoryMap[Category] = NewPage
        if. set PlayerCarouselPageMap[Agent] = CategoryMap

    # --- 3-Slot Carousel Pagination (Unlocked Only) ---
    GetUnlockedItemsForCategory(Agent : agent, Category : customization_type)<transacts> : []customization_item_def =
        var Results : []customization_item_def = array{}
        for (Item : GetMasterCatalog()):
            if (Item.Type = Category):
                if (UnlockAllForTesting? or IsItemUnlocked(Agent, Item.Id)?):
                    set Results += array{ Item }
        return Results

    GetCarouselPageData<public>(Agent : agent, Category : customization_type) : carousel_page_data =
        GetOrInitializePlayerCustomization(Agent)
        Unlocked := GetUnlockedItemsForCategory(Agent, Category)
        TotalItems := Unlocked.Length
        TotalPages := if (T := Ceil[(TotalItems * 1.0) / 3.0], T > 0) then T else 1

        CurrentPage := GetPlayerPage(Agent, Category)
        SafePage := if (CurrentPage >= 0 and CurrentPage < TotalPages) then CurrentPage else 0

        EquippedId := GetEquippedItemId(Agent, Category)

        Slot0 := GetSlotData(Unlocked, SafePage * 3, EquippedId)
        Slot1 := GetSlotData(Unlocked, SafePage * 3 + 1, EquippedId)
        Slot2 := GetSlotData(Unlocked, SafePage * 3 + 2, EquippedId)

        return carousel_page_data:
            Category := Category
            PageIndex := SafePage
            TotalPages := TotalPages
            TotalUnlockedItems := TotalItems
            Slot1 := Slot0
            Slot2 := Slot1
            Slot3 := Slot2

    GetSlotData(Items : []customization_item_def, Index : int, EquippedId : string)<transacts> : carousel_slot_data =
        if (Item := Items[Index]):
            DisplayName := if (Item.Type = customization_type.Title) then Item.TitleText else Item.Name
            return carousel_slot_data:
                ItemId := Item.Id
                Name := DisplayName
                Thumbnail := Item.Thumbnail
                Tier := Item.Tier
                IsEquipped := if (Item.Id = EquippedId) then true else false
                IsLocked := false
        else:
            return carousel_slot_data:
                ItemId := ""
                Name := ""
                Thumbnail := UI.Unranked
                Tier := customization_tier.Tier1
                IsEquipped := false
                IsLocked := true

    CycleCarouselNext<public>(Agent : agent, Category : customization_type) : carousel_page_data =
        GetOrInitializePlayerCustomization(Agent)
        Unlocked := GetUnlockedItemsForCategory(Agent, Category)
        TotalItems := Unlocked.Length
        TotalPages := if (T := Ceil[(TotalItems * 1.0) / 3.0], T > 0) then T else 1
        CurrentPage := GetPlayerPage(Agent, Category)

        HasEmptySlotOnPage := if (CurrentPage * 3 + 2 >= TotalItems) then true else false
        NextPage := if (HasEmptySlotOnPage? or CurrentPage + 1 >= TotalPages) then 0 else CurrentPage + 1

        SetPlayerPage(Agent, Category, NextPage)
        return GetCarouselPageData(Agent, Category)

    CycleCarouselPrev<public>(Agent : agent, Category : customization_type) : carousel_page_data =
        GetOrInitializePlayerCustomization(Agent)
        Unlocked := GetUnlockedItemsForCategory(Agent, Category)
        TotalItems := Unlocked.Length
        TotalPages := if (T := Ceil[(TotalItems * 1.0) / 3.0], T > 0) then T else 1
        CurrentPage := GetPlayerPage(Agent, Category)

        PrevPage := if (CurrentPage <= 0) then TotalPages - 1 else CurrentPage - 1

        SetPlayerPage(Agent, Category, PrevPage)
        return GetCarouselPageData(Agent, Category)

    ApplyEquippedBackpackVfx<public>(Agent : agent) : void =
        for (P : BackpackVfxPowerups) do P.Clear(Agent)
        BackpackId := GetEquippedItemId(Agent, customization_type.Backpack)
        if (Def := FindItemDef(BackpackId)?):
            if (Powerup := BackpackVfxPowerups[Def.VfxIndex]):
                Powerup.Pickup(Agent)

    # --- Blueprint Prop Elimination Effect (Spawns at Victim Position and Auto-Disposes) ---
    PlayKillEffectAt<public>(Killer : agent, VictimFC : fort_character) : void =
        spawn { ExecuteKillEffect(Killer, VictimFC) }

    ExecuteKillEffect(Killer : agent, VictimFC : fort_character)<suspends> : void =
        PlayerPos := VictimFC.GetTransform()
        KillEffectId := GetEquippedItemId(Killer, customization_type.KillEffect)

        var TargetAsset : creative_prop_asset = DefaultKillEffectProp
        if (Def := FindItemDef(KillEffectId)?):
            if (Asset := KillEffectPropAssets[Def.VfxIndex]):
                set TargetAsset = Asset

        if (NewProp := SpawnProp(TargetAsset, PlayerPos)(0)?):
            Sleep(3.0)
            NewProp.Dispose()