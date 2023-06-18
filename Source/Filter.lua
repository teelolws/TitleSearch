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

local categories = {"PvP", "World Events", "General", "Dungeons & Raids", "Pet Battles", "Scenarios", "Garrisons", "Quests", "Reputation", "Professions", "Class Halls"}
local categoriesToID = {["PvP"] = 1, ["World Events"] = 2, ["General"] = 3, ["Dungeons & Raids"] = 4, ["Pet Battles"] = 5, ["Scenarios"] = 6, ["Garrisons"] = 7, ["Quests"] = 8, ["Reputation"] = 9, ["Professions"] = 10, ["Class Halls"] = 11}
local sourceFilter = {}

local function SetSourceFilter(source, checked)
    sourceFilter[source] = checked
end

local function GetSourceFilter(source)
    if sourceFilter[source] == nil then return true end
    return sourceFilter[source]
end

local function SetAllSourceFilters(checked)
    for i = 1, 99 do
        sourceFilter[i] = checked
    end
end

local function GetNumSources()
    return #categories
end

local function GetSourceName(index)
    return categories[index]
end

local STRIPE_COLOR = {r=0.9, g=0.9, b=1};
local function setStripe(button, elementData)
    if not button then
        button = elementData.button
    end
    
    if not button then
        DevTools_Dump(elementData)
    end
    
    if (elementData.index % 2 == 0) then
		button.Stripe:SetColorTexture(STRIPE_COLOR.r, STRIPE_COLOR.g, STRIPE_COLOR.b);
		button.Stripe:SetAlpha(0.1);
		button.Stripe:Show();
	else
		button.Stripe:Hide();
	end
end

local function FullRefresh()
    PaperDollTitlesPane_UpdateScrollBox()
    
    addon:UpdateDB()
    
    local dataProvider = PaperDollFrame.TitleManagerPane.ScrollBox:GetDataProvider()
    
    if not TitleSearchDB then TitleSearchDB = {} end
    if not TitleSearchDB.favourites then TitleSearchDB.favourites = {} end
    local favourites = TitleSearchDB.favourites
    
    if knownFilter then
        local removed = {}
        local normal = {}
        dataProvider:ReverseForEach(function(data)
            if data.index == 1 then return end
            if favourites[data.playerTitle.id] then
                table.insert(removed, data)
            else
                table.insert(normal, data)
            end
            dataProvider:Remove(data)
        end)
        
        for i, data in ipairs(removed) do
            if (not addon.TitleDB[data.playerTitle.id]) or GetSourceFilter(categoriesToID[addon.TitleDB[data.playerTitle.id].category]) then
                data.index = i+1
                table.insert(dataProvider.collection, 2, data)
            end
        end
        
        for i, data in ipairs(normal) do
            if (not addon.TitleDB[data.playerTitle.id]) or GetSourceFilter(categoriesToID[addon.TitleDB[data.playerTitle.id].category]) then
                data.index = i + #removed
                table.insert(dataProvider.collection, #removed+2, data)
            end
        end
    else
        dataProvider:ReverseForEach(function(data)
            dataProvider:Remove(data)
        end)
    end
    
    local index = #dataProvider.collection + 1
    if unknownFilter then
        dataProvider:Insert({index=index, divider=true})
        index = index + 1
        
        for _, data in ipairs(addon.unknownTitles) do
            if GetSourceFilter(categoriesToID[data.category]) then
                dataProvider:Insert({index=index, playerTitle={id=data.oid, name=GetTitleName(data.oid)}, unlearned=true, category=data.category, source=data.source})
                index = index + 1
            end
        end
    end
    
    if unobtainableFilter then
        dataProvider:Insert({index=index, divider=true})
        index = index + 1
        
        for _, data in ipairs(addon.unobtainableTitles) do
            if GetSourceFilter(categoriesToID[data.category]) then
                dataProvider:Insert({index=index, playerTitle={id=data.oid, name=GetTitleName(data.oid)}, unobtainable=true, category=data.category, source=data.source})
                index = index + 1
            end
        end
    end
end

filterButton:SetResetFunction(function()
    knownFilter, unknownFilter, unobtainableFilter = true, true, false
    FullRefresh()
end)

local function IsSourceChecked(source)
	return GetSourceFilter(source)
end

local function SetSourceChecked(source, checked)
	if IsSourceChecked(source) ~= checked then
		SetSourceFilter(source, checked);

		FullRefresh()
	end
end

local function SetAllSourcesChecked(checked)
	SetAllSourceFilters(checked)

	FullRefresh()
	LibDD:UIDropDownMenu_Refresh(parent.filterDropDown, L_UIDROPDOWNMENU_MENU_VALUE, L_UIDROPDOWNMENU_MENU_LEVEL)
end

do
    local function OpenCollectedFilterDropDown(self, level)
		if level then
			local filterSystem = {
          		onUpdate = UpdateResetFiltersButtonVisibility,
          		filters = {
          			{ type = FilterComponent.Checkbox, text = COLLECTED, set = function(value) knownFilter = value FullRefresh() end, isSet = function() return knownFilter end },
          			{ type = FilterComponent.Checkbox, text = NOT_COLLECTED, set = function(value) unknownFilter = value FullRefresh() end, isSet = function() return unknownFilter end },
                    { type = FilterComponent.Checkbox, text = MOUNT_JOURNAL_FILTER_UNUSABLE, set = function(value) unobtainableFilter = value FullRefresh() end, isSet = function() return unobtainableFilter end },
                    { type = FilterComponent.Submenu, text = SOURCES, value = 1, childrenInfo = {
            				filters = {
            					{ type = FilterComponent.TextButton, 
            					  text = CHECK_ALL,
            					  set = function() SetAllSourcesChecked(true) end, 
            					},
            					{ type = FilterComponent.TextButton,
            					  text = UNCHECK_ALL,
            					  set = function() SetAllSourcesChecked(false) end, 
            					},
            					{ type = FilterComponent.DynamicFilterSet,
            					  buttonType = FilterComponent.Checkbox, 
            					  set = function(filter, value)	SetSourceChecked(filter, value) end,
            					  isSet = function(source) return IsSourceChecked(source) end,
            					  numFilters = GetNumSources,
            					  nameFunction = GetSourceName,
            					},
            				},
        			    },
                    },
          		},
      		}

        	addon.FilterDropDownSystem.Initialize(self, filterSystem, level);
		end
	end
    UIDropDownMenu_Initialize(parent.filterDropDown, OpenCollectedFilterDropDown, "MENU")
end

function PaperDollTitlesPane_InitButton(button, elementData)
    elementData.button = button
    if elementData.divider then
        button.text:SetText("")
        button:SetEnabled(false)
        setStripe(button, elementData)
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
    
    setStripe(button, elementData)
    
    if elementData.unlearned then
        button.text:SetTextColor(1, 1, 1)
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
        button:SetScript("OnEnter", nil)
    else
        button.text:SetTextColor(1.0, 0.82, 0)
        button:SetScript("OnEnter", nil)
    end
    
    button:RegisterForClicks("LeftButtonDown", "RightButtonDown")
    button:SetScript("OnClick", function(self, button, down)
        if button == "RightButton" then
            TitleSearchDB.favourites[self.titleId] = not TitleSearchDB.favourites[self.titleId]
            PaperDollTitlesPane_Update()
        else
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
            SetCurrentTitle(self.titleId);
        end
    end)
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

