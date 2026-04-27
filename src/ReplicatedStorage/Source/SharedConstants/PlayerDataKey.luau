--!strict

--[[
	Keys used by the PlayerData system. Every top-level value persisted per player
	needs an entry here. Add a new key here and a default value in DefaultPlayerData.luau.

	MVP schema is LOCKED at 7 keys + 1 meta per ADR-0011: Persistence Schema (Amended 2026-04-27).
	Adding a key outside the MVP / VS+ / Alpha+ scope requires an ADR-0011 amendment.

	Pillar 4 (anti-P2W) categorisation per persisted key:
	  - Coins           — lifetime-statistic (soft currency, MSM Result-entry grant only)
	  - OwnedSkins      — cosmetic (set of owned skin IDs)
	  - SelectedSkin    — cosmetic (currently equipped skin)
	  - LifetimeAbsorbs — lifetime-statistic (analytics; aggregated per round at T6/T7/T8)
	  - LifetimeWins    — lifetime-statistic (analytics; incremented at T6/T7/T8 if winner)
	  - FtueStage       — FTUE-progress (onboarding state machine)
	  - Inventory       — cosmetic (constrained: ContainerByCategory may register cosmetic
	                                 ItemCategories ONLY; non-cosmetic categories are a
	                                 code-review reject per ADR-0011 Amendment 1)

	Deferred keys (NOT in MVP — bump _schemaVersion when these systems land):
	  VS+   (v1 → v2): DailyQuestState, LastDailyResetTime          — Daily Quest System
	  Alpha+ (v2 → v3): AnalyticsOptIn, AccessibilitySettings,
	                    LastShopRefreshTime                         — Settings + Shop systems
--]]

export type EnumType =
	"Coins"
	| "OwnedSkins"
	| "SelectedSkin"
	| "LifetimeAbsorbs"
	| "LifetimeWins"
	| "FtueStage"
	| "Inventory"

local PlayerDataKey = {
	Coins = "Coins" :: "Coins",                       -- lifetime-statistic (soft currency)
	OwnedSkins = "OwnedSkins" :: "OwnedSkins",        -- cosmetic
	SelectedSkin = "SelectedSkin" :: "SelectedSkin",  -- cosmetic
	LifetimeAbsorbs = "LifetimeAbsorbs" :: "LifetimeAbsorbs", -- lifetime-statistic (analytics)
	LifetimeWins = "LifetimeWins" :: "LifetimeWins",  -- lifetime-statistic (analytics)
	FtueStage = "FtueStage" :: "FtueStage",           -- FTUE-progress
	Inventory = "Inventory" :: "Inventory",           -- cosmetic (cosmetic-categories only — Amendment 1)
}

return PlayerDataKey
