local gfind = string.gmatch or string.gfind
local mSASuperWoWDetection = false

local frame=CreateFrame("Frame");
frame:RegisterEvent("VARIABLES_LOADED");
frame:SetScript("OnEvent",function(self,event,...)

	-- Set up varaibles
	if not MailSendeeAutocomplete then MailSendeeAutocomplete = {} end
	if not MailSendeeAutocomplete["alts"] then MailSendeeAutocomplete["alts"] = {} end
	if not MailSendeeAutocomplete["prevSendees"] then MailSendeeAutocomplete["prevSendees"] = {} end

	-- Save player name
	MailSendeeAutocomplete["alts"][UnitName("player")] = true

	-- SuperWoW Detection & SuperWoW Import
	if GetPlayerBuffID and CombatLogAdd and SpellInfo then
		mSASuperWoWDetection = true
		local import = ImportFile("MailSendeeAutocomplete")

		for v in gfind(import, "[^;]+") do
			_,_,alt = string.find(v,("A:(.*)"))
			if alt then
				MailSendeeAutocomplete["alts"][alt] = true
			end
			_,_,prev = string.find(v,("P:(.*)"))
			if prev then
				MailSendeeAutocomplete["prevSendees"][prev] = true
			end
		end

	end
end);

function SendMailFrame_SendeeAutocomplete()
	local text = this:GetText();
	local textlen = strlen(text);
	local numFriends, name;

	-- First check saved alt names list
	for name,bool in pairs( MailSendeeAutocomplete["alts"] ) do

		if bool == true then
			if ( strfind(strupper(name), strupper(text), 1, 1) == 1 ) then
				this:SetText(name);
				this:HighlightText(textlen, -1);
				return;
			end
		end

	end

	-- Next check saved previous sendee names list
	for name,bool in pairs( MailSendeeAutocomplete["prevSendees"] ) do

		if bool == true then
			if ( strfind(strupper(name), strupper(text), 1, 1) == 1 ) then
				this:SetText(name);
				this:HighlightText(textlen, -1);
				return;
			end
		end

	end

	-- Next check your friends list
	numFriends = GetNumFriends();
	if ( numFriends > 0 ) then
		for i=1, numFriends do
			name = GetFriendInfo(i);
			if ( strfind(strupper(name), strupper(text), 1, 1) == 1 ) then
				this:SetText(name);
				this:HighlightText(textlen, -1);
				return;
			end
		end
	end

	-- No match, check your guild list
	numFriends = GetNumGuildMembers(true);	-- true to include offline members
	if ( numFriends > 0 ) then
		for i=1, numFriends do
			name = GetGuildRosterInfo(i);
			if ( strfind(strupper(name), strupper(text), 1, 1) == 1 ) then
				this:SetText(name);
				this:HighlightText(textlen, -1);
				return;
			end
		end
	end
end

-- Hijack SendMail() so we can save the name of the recipient
local SendMailOriginal = SendMail
function SendMail(recipient, subject, body)
	MailSendeeAutocomplete["prevSendees"][recipient] = true

	-- Export MailSendeeAutocomplete via SuperWoW, if it's detected.
	if mSASuperWoWDetection then
		local output = ''
		for name,val in pairs( MailSendeeAutocomplete["alts"] ) do
			output = output .. "A:"..name..";"
		end
		for name,val in pairs( MailSendeeAutocomplete["prevSendees"] ) do
			output = output .. "P:"..name..";"
		end
		ExportFile("MailSendeeAutocomplete",output)
	end

	SendMailOriginal(recipient, subject, body)
end
