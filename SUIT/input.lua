-- This file is part of SUIT, copyright (c) 2016 Matthias Richter

local BASE = (...):match('(.-)[^%.]+$')
local utf8 = require 'utf8'

local function split(str, pos)
	local offset = utf8.offset(str, pos) or 0
	return str:sub(1, offset-1), str:sub(offset)
end

return function(core, input, ...)
	local opt, x,y,w,h = core.getOptionsAndSize(...)
	opt.font = opt.font or love.graphics.getFont()
	opt.field = opt.field or "text"
	opt.id = opt.id or input
	opt.type = opt.type or "string"
	opt.nobg = opt.nobg or false

	input[opt.field] = tostring(input[opt.field])

	local text_width = opt.font:getWidth(input[opt.field])
	w = w or text_width + 6
	h = h or opt.font:getHeight() + 4

	input[opt.field] = input[opt.field] or ""
	input[opt.field..".cursor"] = math.max(1, math.min(utf8.len(input[opt.field])+1, input[opt.field..".cursor"] or utf8.len(input[opt.field])+1))
	-- cursor is position *before* the character (including EOS) i.e. in "hello":
	--   position 1: |hello
	--   position 2: h|ello
	--   ...
	--   position 6: hello|

	-- get size of text and cursor position
	opt[opt.field..".cursor_pos"] = 0
	if input[opt.field..".cursor"] > 1 then
		local s = input[opt.field]:sub(1, utf8.offset(input[opt.field], input[opt.field..".cursor"])-1)
		opt[opt.field..".cursor_pos"] = opt.font:getWidth(s)
	end

	-- compute drawing offset
	local wm = w - 6 -- consider margin
	input.text_draw_offset = input.text_draw_offset or 0
	if opt[opt.field..".cursor_pos"] - input.text_draw_offset < 0 then
		-- cursor left of input box
		input.text_draw_offset = opt[opt.field..".cursor_pos"]
	end
	if opt[opt.field..".cursor_pos"] - input.text_draw_offset > wm then
		-- cursor right of input box
		input.text_draw_offset = opt[opt.field..".cursor_pos"] - wm
	end
	if text_width - input.text_draw_offset < wm and text_width > wm then
		-- text bigger than input box, but does not fill it
		input.text_draw_offset = text_width - wm
	end

	-- user interaction
	if input.forcefocus ~= nil and input.forcefocus then
		core.active = opt.id
		input.forcefocus = false
	end

	opt.state = core:registerHitbox(opt.id, x,y,w,h)
	opt.hasKeyboardFocus = core:grabKeyboardFocus(opt.id)

	if (core.candidate_text.text == "") and opt.hasKeyboardFocus then
		local keycode,char = core:getPressedKey()
		-- text input
		if char and char ~= "" then
				local a,b = split(input[opt.field], input[opt.field..".cursor"])
				local strres = table.concat{a, char, b}
			if opt.type == "string" or
				(opt.type == "number" and tonumber(strres)) then
				input[opt.field..".cursor"] = input[opt.field..".cursor"] + utf8.len(char)
				input[opt.field] = strres
			end
		end

		-- text editing
		if keycode == 'backspace' then
			local a,b = split(input[opt.field], input[opt.field..".cursor"])
			input[opt.field] = table.concat{split(a,utf8.len(a)), b}
			input[opt.field..".cursor"] = math.max(1, input[opt.field..".cursor"]-1)
		elseif keycode == 'delete' then
			local a,b = split(input[opt.field], input[opt.field..".cursor"])
			local _,b = split(b, 2)
			input[opt.field] = table.concat{a, b}
		end

		-- cursor movement
		if keycode =='left' then
			input[opt.field..".cursor"] = math.max(0, input[opt.field..".cursor"]-1)
		elseif keycode =='right' then -- cursor movement
			input[opt.field..".cursor"] = math.min(utf8.len(input[opt.field])+1, input[opt.field..".cursor"]+1)
		elseif keycode =='home' then -- cursor movement
			input[opt.field..".cursor"] = 1
		elseif keycode =='end' then -- cursor movement
			input[opt.field..".cursor"] = utf8.len(input[opt.field])+1
		end

		-- move cursor position with mouse when clicked on
		if core:mouseReleasedOn(opt.id) then
			local mx = core:getMousePosition() - x + input.text_draw_offset
			input[opt.field..".cursor"] = utf8.len(input[opt.field]) + 1
			for c = 1,input[opt.field..".cursor"] do
				local s = input[opt.field]:sub(0, utf8.offset(input[opt.field], c)-1)
				if opt.font:getWidth(s) >= mx then
					input[opt.field..".cursor"] = c-1
					break
				end
			end
		end
	end

	input.candidate_text = {text=core.candidate_text.text, start=core.candidate_text.start, length=core.candidate_text.length}
	core:registerDraw(opt.draw or core.theme.Input, input, opt, x,y,w,h)

	input[opt.field] = input[opt.field]

	return {
		id = opt.id,
		hit = core:mouseReleasedOn(opt.id),
		submitted = core:keyPressedOn(opt.id, "return"),
		hovered = core:isHovered(opt.id),
		entered = core:isHovered(opt.id) and not core:wasHovered(opt.id),
		left = not core:isHovered(opt.id) and core:wasHovered(opt.id)
	}
end
