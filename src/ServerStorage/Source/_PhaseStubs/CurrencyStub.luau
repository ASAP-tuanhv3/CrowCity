--!strict

--[[
	CurrencyStub — placeholder for the currency system.
	Real implementation: src/ServerStorage/Source/Currency/ (currency epic).
	Sole caller of `grantMatchRewards`: MSM Result entry path.

	Per ADR-0005 §Result-entry ordering invariant + ADR-0011 §Coins grant only
	at MSM Result entry (manifest L126):
	   _winnerId resolved → setWinner → getPlacements → grantMatchRewards →
	   MatchStateChanged broadcast.

	NEVER grant currency mid-round. NEVER grant during BindToClose (manifest L142).
--]]

local CurrencyStub = {}

export type Placement = {
	crowdId: string,
	userId: number,
	placement: number,
	crowdCount: number,
	eliminationTime: number?,
}

--- Grants per-placement coin rewards for the round. Stub is no-op; real
--- implementation will look up the placement→coin table and call
--- PlayerDataServer.updateValue per placement.
--- Caller invariant: MSM `_handleResultEntry` is sole caller.
function CurrencyStub.grantMatchRewards(_placements: { Placement }): ()
	-- No-op — real implementation lives in Currency (epic: currency).
end

return CurrencyStub
