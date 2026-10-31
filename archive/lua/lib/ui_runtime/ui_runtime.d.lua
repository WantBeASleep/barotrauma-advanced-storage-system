---@meta

---@class ui_runtime.LoadArgs
---@field module_path string

---@class ui_runtime.Dependencies
---@field errors errors.Lib
---@field log logger.logger

---@class ui_runtime.DependencyState
---@field errors errors.Lib|nil
---@field log logger.logger|nil

---@class ui_runtime.InternalDependencies
---@field errors errors.Lib
---@field log logger.logger|nil
---@field ERROR ui_runtime.Error

---@class ui_runtime.Error
---@field dependencies_required string
---@field errors_required string
---@field log_required string
---@field path_required string
---@field open_failed string
---@field read_failed string
---@field close_failed string
---@field empty_file string
---@field json_parse_failed string
---@field parsed_layout_required string
---@field layout_required string
---@field schema_invalid string
---@field unknown_top_level_field string
---@field node_required string
---@field node_type_invalid string
---@field node_id_required string
---@field dynamic_field string
---@field unknown_field string
---@field size_conflict string
---@field size_required string
---@field number_pair_required string
---@field number_quad_required string
---@field color_required string
---@field children_array_required string
---@field duplicate_child_id string
---@field templates_required string
---@field template_name_required string
---@field string_required string
---@field number_required string
---@field boolean_required string
---@field enum_invalid string
---@field component_type_unknown string
---@field relative_asset_mod_path_required string
---@field image_load_failed string
---@field content_required string
---@field node_not_found string
---@field node_type_mismatch string
---@field tree_instantiator_required string
---@field template_not_found string
---@field template_parent_required string
---@field dropdown_items_required string
---@field callback_required string
---@field text_required string
---@field sprite_path_required string
---@field source_rect_invalid string
---@field numeric_value_required string
---@field boolean_value_required string

---@class ui_runtime.Lib
---@field deps ui_runtime.DependencyState
---@field ERROR ui_runtime.Error
---@field init fun(dependencies: ui_runtime.Dependencies): ui_runtime.Lib
---@field load_layout fun(path: string): table
---@field validate fun(layout: table)
---@field render fun(layout: table, parent: Barotrauma.RectTransform, options: ui_runtime.RenderOptions|nil): ui_runtime.Tree

---@class ui_runtime.RenderOptions
---@field mod_path string|nil

---@class ui_runtime.LayoutLoader
---@field init fun(dependencies: ui_runtime.InternalDependencies): ui_runtime.LayoutLoader
---@field load fun(path: string): table

---@class ui_runtime.Validator
---@field init fun(dependencies: ui_runtime.InternalDependencies): ui_runtime.Validator
---@field validate fun(layout: table)

---@class ui_runtime.RendererLoadArgs
---@field module_path string

---@class ui_runtime.Renderer
---@field deps ui_runtime.InternalDependencyState
---@field init fun(dependencies: ui_runtime.InternalDependencies): ui_runtime.Renderer
---@field render fun(layout: table, parent: Barotrauma.RectTransform, options: ui_runtime.RenderOptions|nil): ui_runtime.Tree

---@class ui_runtime.InternalDependencyState
---@field errors errors.Lib|nil
---@field log logger.logger|nil
---@field ERROR ui_runtime.Error|nil

---@class ui_runtime.NodeClass
---@field deps ui_runtime.InternalDependencyState
---@field init fun(dependencies: ui_runtime.InternalDependencies): ui_runtime.NodeClass
---@field new fun(component: Barotrauma.GUIComponent, node_type: string, id: string, path: string, parent: ui_runtime.Node|nil): ui_runtime.Node

---@class ui_runtime.TreeClass
---@field deps ui_runtime.InternalDependencyState
---@field init fun(dependencies: ui_runtime.InternalDependencies): ui_runtime.TreeClass
---@field new fun(root: ui_runtime.Node, templates: table<string, table>, diagnostics: ui_runtime.Diagnostics): ui_runtime.Tree

---@class ui_runtime.Diagnostics
---@field warnings ui_runtime.DiagnosticWarning[]

---@class ui_runtime.DiagnosticWarning
---@field id string
---@field kind string
---@field message string

---@class ui_runtime.Tree
---@field root ui_runtime.Node
---@field templates table<string, table>
---@field diagnostics ui_runtime.Diagnostics
---@field instantiate fun(template_name: string, parent_node: ui_runtime.Node): ui_runtime.Node
---@field get fun(self: ui_runtime.Tree, path: string): ui_runtime.Node
---@field maybe fun(self: ui_runtime.Tree, path: string): ui_runtime.Node|nil
---@field create fun(self: ui_runtime.Tree, template_name: string, parent: ui_runtime.Node|ui_runtime.ContainerAdapter): ui_runtime.Node

---@class ui_runtime.Node
---@field id string
---@field type string
---@field path string
---@field _component Barotrauma.GUIComponent
---@field children ui_runtime.Node[]
---@field index table<string, ui_runtime.Node>
---@field parent ui_runtime.Node|nil
---@field add_child fun(self: ui_runtime.Node, child: ui_runtime.Node, indexable: boolean|nil)
---@field get fun(self: ui_runtime.Node, path: string): ui_runtime.Node
---@field maybe fun(self: ui_runtime.Node, path: string): ui_runtime.Node|nil
---@field component fun(self: ui_runtime.Node): Barotrauma.GUIComponent
---@field remove fun(self: ui_runtime.Node)
---@field clear fun(self: ui_runtime.Node)
---@field set_enabled fun(self: ui_runtime.Node, value: boolean)
---@field set_visible fun(self: ui_runtime.Node, value: boolean)
---@field set_color fun(self: ui_runtime.Node, color: Microsoft.Xna.Framework.Color)
---@field as_text fun(self: ui_runtime.Node): ui_runtime.TextAdapter
---@field as_button fun(self: ui_runtime.Node): ui_runtime.ButtonAdapter
---@field as_dropdown fun(self: ui_runtime.Node): ui_runtime.DropDownAdapter
---@field as_slider fun(self: ui_runtime.Node): ui_runtime.SliderAdapter
---@field as_image fun(self: ui_runtime.Node): ui_runtime.ImageAdapter
---@field as_container fun(self: ui_runtime.Node): ui_runtime.ContainerAdapter

---@class ui_runtime.TextAdapter
---@field set_text fun(self: ui_runtime.TextAdapter, value: string)

---@class ui_runtime.ButtonAdapter
---@field on_click fun(self: ui_runtime.ButtonAdapter, callback: fun(): boolean)

---@class ui_runtime.DropDownAdapter
---@field set_items fun(self: ui_runtime.DropDownAdapter, items: table)
---@field set_selected fun(self: ui_runtime.DropDownAdapter, value: any)
---@field on_selected fun(self: ui_runtime.DropDownAdapter, callback: fun(value: any))

---@class ui_runtime.SliderAdapter
---@field set_value fun(self: ui_runtime.SliderAdapter, value: number)
---@field on_changed fun(self: ui_runtime.SliderAdapter, callback: fun(value: number))

---@class ui_runtime.ImageAdapter
---@field set_sprite fun(self: ui_runtime.ImageAdapter, path: string, source_rect: ui_runtime.SourceRect|nil)
---@field set_offset fun(self: ui_runtime.ImageAdapter, x: number, y: number)
---@field set_size fun(self: ui_runtime.ImageAdapter, width: number, height: number)

---@class ui_runtime.ContainerAdapter
---@field _node ui_runtime.Node
---@field clear fun(self: ui_runtime.ContainerAdapter)

---@class ui_runtime.SourceRect
---@field x number|nil
---@field y number|nil
---@field width number|nil
---@field height number|nil
---@field [1] number|nil
---@field [2] number|nil
---@field [3] number|nil
---@field [4] number|nil
