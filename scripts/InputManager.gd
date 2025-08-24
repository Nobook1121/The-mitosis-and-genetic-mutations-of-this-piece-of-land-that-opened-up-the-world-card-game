# 输入管理器脚本
# 核心职责：统一处理鼠标输入事件，通过射线检测判断交互对象（卡牌/牌堆），并触发对应逻辑
extends Node2D

# 定义输入信号：鼠标左键点击时发射（供其他节点响应点击事件）
signal left_mouse_button_clicked
# 定义输入信号：鼠标左键释放时发射（供其他节点响应释放事件，如结束拖拽）
signal left_mouse_button_released

# 碰撞掩码常量 - 用于区分不同交互对象的碰撞检测
const COLLISION_MASK_CARD = 1         # 卡牌的碰撞层掩码（与CardsManager中定义一致）
const COLLISION_MASK_DECK = 4         # 牌堆的碰撞层掩码（用于识别牌堆交互）

# 变量定义
var card_manager_reference  # 卡牌管理器的引用（用于触发卡牌拖拽逻辑）
var deck_reference          # 牌堆的引用（用于触发抽卡逻辑）

# 节点就绪时调用（初始化引用）
func _ready() -> void:
	# 获取卡牌管理器节点的引用（路径需根据实际场景结构调整）
	card_manager_reference = $"../CardsManager"
	# 获取牌堆节点的引用（路径需根据实际场景结构调整）
	deck_reference = $"../Deck"


# 输入事件处理函数（Godot引擎回调，所有输入事件都会经过这里）
func _input(event):
	# 过滤：只处理鼠标左键的事件（忽略其他按键/鼠标键）
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:  # 鼠标左键按下时
			# 发射左键点击信号（通知其他节点，如需要响应点击的UI）
			emit_signal("left_mouse_button_clicked")
			# 执行射线检测，判断鼠标位置是否有可交互对象（卡牌/牌堆）
			raycast_at_cursor()
		else:  # 鼠标左键释放时
			# 发射左键释放信号（主要用于卡牌管理器结束拖拽）
			emit_signal("left_mouse_button_released")
			# 释放时无需额外处理，逻辑由接收信号的节点（如CardsManager）实现
			pass 


## 射线检测：在鼠标位置发射射线，判断点击的是卡牌还是牌堆
func raycast_at_cursor():
	# 获取2D物理空间状态（用于执行碰撞检测）
	var space_state = get_world_2d().direct_space_state
	# 创建点查询参数（检测鼠标位置的碰撞体）
	var parameters = PhysicsPointQueryParameters2D.new()
	# 设置检测点为当前鼠标在全局坐标系中的位置
	parameters.position = get_global_mouse_position()
	# 允许检测Area2D类型的碰撞体（卡牌和牌堆通常用Area2D作为交互区域）
	parameters.collide_with_areas = true	
	# 执行点查询，返回所有碰撞到的对象（数组）
	var result = space_state.intersect_point(parameters)
	
	# 如果检测到碰撞对象
	if result.size() > 0:
		# 获取碰撞对象的碰撞掩码（用于判断对象类型）
		var result_collision_mask = result[0].collider.collision_mask
		
		# 如果碰撞对象是卡牌（掩码匹配COLLISION_MASK_CARD）
		if result_collision_mask == COLLISION_MASK_CARD:
			# 获取卡牌节点（假设碰撞体是卡牌的子节点，通过get_parent()获取卡牌本身）
			var card_found = result[0].collider.get_parent()
			if card_found:  # 确认找到卡牌节点
				# 通知卡牌管理器开始拖拽该卡牌
				card_manager_reference.start_drag(card_found)
		
		# 如果碰撞对象是牌堆（掩码匹配COLLISION_MASK_DECK）
		elif result_collision_mask == COLLISION_MASK_DECK:
			# 通知牌堆执行抽卡逻辑
			deck_reference.draw_card()
