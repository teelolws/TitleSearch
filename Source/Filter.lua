local addonName, addon = ...
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")

local parent = PaperDollFrame.TitleManagerPane
            
parent.FilterButton = CreateFrame("DropDownToggleButton", "TitleSearchFilterButton", parent, "UIResettableDropdownButtonTemplate")
local filterButton = parent.FilterButton

filterButton.Text:SetText(FILTER)
filterButton:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 26, -1)

filterButton:HookScript("OnMouseDown", function(self)
    LibDD:ToggleDropDownMenu(1, nil, self:GetParent().filterDropDown, self, 74, 15)
end)

parent.filterDropDown = LibDD:Create_UIDropDownMenu("TitleSearchFilterDropDown", parent)

local knownFilter = true
local unknownFilter = true
local unobtainableFilter = false

local function IsUsingDefaultFilters()
    return knownFilter and unknownFilter and (not unobtainableFilter)
end

local function UpdateResetFiltersButtonVisibility()
	filterButton.ResetButton:SetShown(not IsUsingDefaultFilters())
end
UpdateResetFiltersButtonVisibility()

local function FullRefresh()
    PaperDollTitlesPane_UpdateScrollBox()
    
    local dataProvider = PaperDollFrame.TitleManagerPane.ScrollBox:GetDataProvider()
    
    if not knownFilter then
        dataProvider:ReverseForEach(function(data)
            dataProvider:Remove(data)
        end)
    end
    
    if unknownFilter then
        dataProvider:Insert({divider=true})
        
        for _, data in ipairs(addon.unknownTitles) do
            dataProvider:Insert({index=data.oid, playerTitle={id=data.oid, name=GetTitleName(data.oid)}, unlearned=true, category=data.category, source=data.source})
        end
    end
    
    if unobtainableFilter then
        dataProvider:Insert({divider=true})
        
        for _, data in ipairs(addon.unobtainableTitles) do
            dataProvider:Insert({index=data.oid, playerTitle={id=data.oid, name=GetTitleName(data.oid)}, unobtainable=true, category=data.category, source=data.source})
        end
    end
end

filterButton:SetResetFunction(function()
    knownFilter, unknownFilter, unobtainableFilter = true, true, false
    FullRefresh()
end)

do
    local function OpenCollectedFilterDropDown(self, level)
		if level then
			local filterSystem = {
          		onUpdate = UpdateResetFiltersButtonVisibility,
          		filters = {
          			{ type = FilterComponent.Checkbox, text = COLLECTED, set = function(value) knownFilter = value FullRefresh() end, isSet = function() return knownFilter end },
          			{ type = FilterComponent.Checkbox, text = NOT_COLLECTED, set = function(value) unknownFilter = value FullRefresh() end, isSet = function() return unknownFilter end },
                    { type = FilterComponent.Checkbox, text = MOUNT_JOURNAL_FILTER_UNUSABLE, set = function(value) unobtainableFilter = value FullRefresh() end, isSet = function() return unobtainableFilter end },
          		},
      		}

        	addon.FilterDropDownSystem.Initialize(self, filterSystem, level);
		end
	end
    UIDropDownMenu_Initialize(parent.filterDropDown, OpenCollectedFilterDropDown, "MENU")
end

local STRIPE_COLOR = {r=0.9, g=0.9, b=1};
function PaperDollTitlesPane_InitButton(button, elementData)
    if elementData.divider then
        button.text:SetText("")
        button:SetEnabled(false)
        return
    else
        button:SetEnabled(true)
    end
    
	local index = elementData.index;
	local playerTitle = elementData.playerTitle;
	button.text:SetText(playerTitle.name);
	button.titleId = playerTitle.id;
	
	local selected = PaperDollFrame.TitleManagerPane.selected == playerTitle.id;
	PaperDollTitlesPane_SetButtonSelected(button, selected);

	if (index == 1) then
		button.BgTop:Show();
		button.BgMiddle:SetPoint("TOP", button.BgTop, "BOTTOM");
	else
		button.BgTop:Hide();
		button.BgMiddle:SetPoint("TOP");
	end

	local playerTitles = PaperDollFrame.TitleManagerPane.titles;
	if (index == #playerTitles) then
		button.BgBottom:Show();
		button.BgMiddle:SetPoint("BOTTOM", button.BgBottom, "TOP");
	else
		button.BgBottom:Hide();
		button.BgMiddle:SetPoint("BOTTOM");
	end
    
    if (index % 2 == 0) then
		button.Stripe:SetColorTexture(STRIPE_COLOR.r, STRIPE_COLOR.g, STRIPE_COLOR.b);
		button.Stripe:SetAlpha(0.1);
		button.Stripe:Show();
	else
		button.Stripe:Hide();
	end
    
    if elementData.unlearned then
        button.text:SetTextColor(1, 1, 1)
        button.Stripe:Hide()
        button:SetScript("OnEnter", function()
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:ClearLines()
            GameTooltip:AddDoubleLine(elementData.category, elementData.source or "")
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    elseif elementData.unobtainable then
        button.text:SetTextColor(0.5, 0.5, 0.5)
        button.Stripe:Show()
        button.Stripe:SetColorTexture(STRIPE_COLOR.r, STRIPE_COLOR.g, STRIPE_COLOR.b)
        button.Stripe:SetAlpha(0.1)
        button:SetScript("OnEnter", nil)
    else
        button.text:SetTextColor(1.0, 0.82, 0)
        button:SetScript("OnEnter", nil)
    end
end

local searchText = ""
local parent = PaperDollFrame.TitleManagerPane

parent.ScrollBox:SetHeight(334)

parent.SearchBox = CreateFrame("EditBox", "TitleSearchEditBox", parent, "SearchBoxTemplate")
local searchBox = parent.SearchBox

searchBox.letters = 40
searchBox:SetSize(105, 20)
searchBox:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 1, 0)
searchBox:HookScript("OnTextChanged", function(self)
	SearchBoxTemplate_OnTextChanged(self);
	searchText = self:GetText()
	PaperDollTitlesPane_Update()
end)

hooksecurefunc("PaperDollTitlesPane_Update", function()
    FullRefresh()
    
    if searchText ~= "" then
        local dataProvider = PaperDollFrame.TitleManagerPane.ScrollBox:GetDataProvider()
        dataProvider:ReverseForEach(function(data)
            if data.playerTitle and (not string.lower(data.playerTitle.name):find(string.lower(searchText))) then
                dataProvider:Remove(data)
            end
        end)
    end
end)

