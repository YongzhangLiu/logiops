/*
 * Copyright 2019-2023 PixlOne
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#ifndef LOGID_ACTION_TOGGLESMARTHIRES_H
#define LOGID_ACTION_TOGGLESMARTHIRES_H

#include <actions/Action.h>
#include <features/SmartShift.h>
#include <features/HiresScroll.h>

namespace logid::actions {

class ToggleSmartHires : public Action {
public:
    static const char* interface_name;

    ToggleSmartHires(Device* dev,
                     const std::shared_ptr<ipcgull::node>& parent);

    ToggleSmartHires(Device* device,
                     [[maybe_unused]] config::ToggleSmartHires& action,
                     const std::shared_ptr<ipcgull::node>& parent) :
            ToggleSmartHires(device, parent) {}

    void press() final;
    void release() final;

    [[nodiscard]] uint8_t reprogFlags() const final;

private:
    std::shared_ptr<features::SmartShift> _smartshift;
    std::shared_ptr<features::HiresScroll> _hires_scroll;
    bool _pressed = false;
};

} // namespace logid::actions

#endif // LOGID_ACTION_TOGGLESMARTHIRES_H
