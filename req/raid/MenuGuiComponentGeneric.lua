MenuGuiComponentGeneric = MenuGuiComponentGeneric or class()
function MenuGuiComponentGeneric:init(ws, fullscreen_ws, node, name)
    self._ws = ws
    self._fullscreen_ws = fullscreen_ws
    self._fullscreen_panel = self._fullscreen_ws:panel():panel({})
    self._panel = self._ws:panel():panel({layer = 20})
    self._init_layer = self._ws:panel():layer()

    self._data = node:parameters().menu_component_data or {}
    self._buttons = {}
    self:_setup()
end

function MenuGuiComponentGeneric:close()
    self._ws:panel():remove(self._panel)
    self._fullscreen_ws:panel():remove(self._fullscreen_panel)
    self._root_panel:clear()
    BLT.Mods:Save()
end

function MenuGuiComponentGeneric:mouse_pressed(o, button, x, y)
    local result = false

    for _, item in ipairs(self._buttons) do
        if item:inside(x, y) then
            if item.mouse_clicked then
                result = item:mouse_clicked(button, x, y)
            end
            break
        end
    end

    if button == Idstring("0") then
        for _, item in ipairs(self._buttons) do
            if item:inside(x, y) then
                if item:parameters().callback then
                    item:parameters().callback()
                end
                managers.menu_component:post_event("menu_enter")
                return true
            end
        end
    end

    return result
end

function MenuGuiComponentGeneric:mouse_moved(o, x, y)
    if managers.menu_scene and managers.menu_scene.input_focus and managers.menu_scene:input_focus() then
        return false
    end
end

function MenuGuiComponentGeneric:mouse_clicked(o, button, x, y)
    if managers.menu_scene and managers.menu_scene.input_focus and managers.menu_scene:input_focus() then
        return false
    end
end

function MenuGuiComponentGeneric:mouse_released(o, button, x, y)
    if managers.menu_scene and managers.menu_scene.input_focus and managers.menu_scene:input_focus() then
        return false
    end
end

function MenuGuiComponentGeneric:mouse_wheel_up(x, y)

end

function MenuGuiComponentGeneric:mouse_wheel_down(x, y)

end

function MenuGuiComponentGeneric:mouse_double_click(o, button, x, y)

end

function MenuGuiComponentGeneric:make_fine_text(text)
    if not alive(text) then
        return
    end
    local x,y,w,h = text:text_rect()
    text:set_size(w, h)
    text:set_position(math.round(text:x()), math.round(text:y()))
end