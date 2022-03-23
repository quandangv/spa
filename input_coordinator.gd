extends Node

const controller_priorities = {"camera":1, "ship":0}
var _explicit_controllers = []
var _implicit_controllers = []
var _implicit_controllers_priorities = []

func register_implicit_controller(type, controller, front = false):
  var priority = controller_priorities[type]
  var index = _implicit_controllers_priorities.bsearch(priority)
  var front_index = index
  while index < len(_implicit_controllers) and _implicit_controllers_priorities[index] == priority: # Check if the controller have already been added
    if _implicit_controllers[index] == controller:
      if front:
        index = front_index
        break
      if index == 0:
        return true
      else:
        return false
    index += 1
  _implicit_controllers_priorities.insert(index, priority)
  _implicit_controllers.insert(index, controller)
  controller.connect("tree_exiting", self, "unregister_implicit_controller", [controller])
  if index == 0:
    if len(_implicit_controllers) >= 2:
      _implicit_controllers[1].lost_input()
    return true
  else:
    return false

func unregister_implicit_controller(controller):
  var index = _implicit_controllers.find(controller)
  if index >= 0:
    _implicit_controllers.remove(index)
    _implicit_controllers_priorities.remove(index)
    controller.disconnect("tree_exiting", self, "unregister_implicit_controller")
    if index == 0 and len(_implicit_controllers) > 0:
      _implicit_controllers.front().gained_input()

func replace_explicit_controllers(controller):
  _explicit_controllers.clear()
  _explicit_controllers.append(controller)
func clear_explicit_controllers():
  _explicit_controllers.clear()
