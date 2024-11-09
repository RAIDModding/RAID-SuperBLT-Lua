MenuGuiComponentGeneric = MenuGuiComponentGeneric or class()
MenuGuiComponentGeneric._buttons = {}
function MenuGuiComponentGeneric:init(ws, fullscreen_ws, node, name)
    self._ws = ws
    self._fullscreen_ws = fullscreen_ws
    self._fullscreen_panel = self._fullscreen_ws:panel():panel({})
    self._panel = self._ws:panel():panel({layer = 20})
    self._init_layer = self._ws:panel():layer()

    self._data = node:parameters().menu_component_data or {}
    self:_setup()
end

function MenuGuiComponentGeneric:update(t, dt)
end

function MenuGuiComponentGeneric:close()
    self._ws:panel():remove(self._panel)
    self._fullscreen_ws:panel():remove(self._fullscreen_panel)
    self._root_panel:clear()
end

function MenuGuiComponentGeneric:mouse_pressed(o, button, x, y)
end

function MenuGuiComponentGeneric:mouse_moved(o, x, y)
end

function MenuGuiComponentGeneric:mouse_clicked(o, button, x, y)
end

function MenuGuiComponentGeneric:mouse_released(o, button, x, y)
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

function MenuGuiComponentGeneric:update_back_button_hover(button, x, y)
end

function MenuGuiComponentGeneric:back_pressed()
    RaidGuiBase:_on_legend_pc_back()
end

function MenuGuiComponentGeneric:move_up()
    -- empty function to prevent crash when using arrow keys on main menu
end

function MenuGuiComponentGeneric:move_down()
    -- empty function to prevent crash when using arrow keys on main menu
end

function MenuGuiComponentGeneric:move_left()
    -- empty function to prevent crash when using arrow keys on main menu
end

function MenuGuiComponentGeneric:move_right()
    -- empty function to prevent crash when using arrow keys on main menu
end

function MenuGuiComponentGeneric:confirm_pressed()
    -- empty function to prevent crash when using arrow keys on main menu
end
