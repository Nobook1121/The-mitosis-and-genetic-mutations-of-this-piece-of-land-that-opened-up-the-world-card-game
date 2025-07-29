# 卡牌交互管理器
# 负责处理卡牌的拖拽、悬停高亮和放置到卡槽的核心逻辑
extends Node2D

# 碰撞掩码常量 - 用于区分不同类型的碰撞体
# 碰撞掩码通过位运算实现不同对象间的碰撞检测过滤
const COLLISION_MASK_CARD = 1         # 卡片的碰撞层掩码
const COLLISION_MASK_CARD_SOLT = 2    # 卡槽的碰撞层掩码

# 变量定义
var screen_size                       # 存储屏幕尺寸，用于限制卡片移动范围
var card_being_dragged                # 跟踪当前正在拖拽的卡片节点
var is_hovering_on_card = false       # 标记是否有卡片正被鼠标悬停
var player_hand_reference             # 引用玩家手牌容器节点，用于卡片的回收和管理

# 节点就绪时调用
func _ready() -> void:
	# 获取屏幕尺寸，用于限制卡片拖拽范围
	screen_size = get_viewport_rect().size
	# 获取玩家手牌容器的引用（路径根据实际场景结构调整）
	player_hand_reference = $"../PlayerHand"

# 每帧更新调用
func _process(delta: float) -> void:
	# 如果有卡片正在被拖拽，更新卡片位置跟随鼠标
	if card_being_dragged:
		# 获取鼠标在全局坐标系中的位置
		var mouse_pos = get_global_mouse_position()
		# 限制卡片在屏幕范围内移动（防止拖出屏幕外）
		card_being_dragged.position = Vector2(
			clamp(mouse_pos.x, 0, screen_size.x),  # x轴限制在0到屏幕宽度
			clamp(mouse_pos.y, 0, screen_size.y)   # y轴限制在0到屏幕高度
		)

# 处理输入事件
func _input(event):
	# 只处理左键鼠标事件
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:  # 鼠标左键按下时
			# 检测鼠标位置是否有卡片
			var card = raycast_check_for_card()
			if card:
				# 开始拖拽检测到的卡片
				start_drag(card)
		else:  # 鼠标左键释放时
			# 如果有正在拖拽的卡片，结束拖拽流程
			if card_being_dragged:
				finish_drag()

# 开始拖拽卡片
func start_drag(card):
	# 记录当前拖拽的卡片
	card_being_dragged = card
	# 拖拽时恢复卡片默认大小（取消悬停放大效果）
	card.scale = Vector2(1, 1)

# 结束卡片拖拽，处理放置逻辑
func finish_drag():
	# 结束拖拽时恢复悬停放大效果
	card_being_dragged.scale = Vector2(1.05, 1.05)
	
	# 检测鼠标释放位置是否有可用卡槽
	var card_slot_found = raycast_check_for_card_solt()
	
	# 如果找到卡槽且卡槽为空
	if card_slot_found and not card_slot_found.card_in_slot:
		# 从手牌中移除该卡片
		player_hand_reference.remove_card_from_hand(card_being_dragged)
		# 将卡片放置到卡槽位置位置
		card_being_dragged.position = card_slot_found.position
		# 禁用卡片的碰撞体（防止再次被选中拖拽）
		card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
		# 标记卡槽已被占用
		card_slot_found.card_in_slot = true
	else:
		# 如果未找到有效卡槽，将卡片放回手牌
		player_hand_reference.add_card_to_hand(card_being_dragged)
	
	# 清除拖拽状态
	card_being_dragged = null

# 连接卡片的悬停信号
# 需在创建卡片时调用此方法，建立信号连接
func connect_card_signal(card):
	# 连接卡片的悬停信号到处理函数
	card.connect("hovered", on_hovered_over_card)
	# 连接卡片的离开悬停信号到处理函数
	card.connect("hovered_off", on_hovered_off_card)

# 鼠标悬停在卡片上时的处理
func on_hovered_over_card(card):
	# 如果当前没有悬停的卡片
	if !is_hovering_on_card:
		is_hovering_on_card = true
		# 高亮显示卡片
		highlight_card(card, true)

# 鼠标离开卡片时的处理
func on_hovered_off_card(card):
	# 如果没有正在拖拽的卡片（拖拽时不处理离开悬停）
	if !card_being_dragged:
		# 取消卡片高亮
		highlight_card(card, false)
		# 检查鼠标是否移动到了另一张卡片上
		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered:
			# 高亮新的悬停卡片
			highlight_card(new_card_hovered, true)
		else:
			# 没有悬停任何卡片
			is_hovering_on_card = false

# 卡片高亮处理（放大并置顶）
func highlight_card(card, hovered):
	if hovered == true:
		# 悬停时放大卡片
		card.scale = Vector2(1.05, 1.05)
		# 提高z轴层级，使卡片显示在其他卡片上方
		card.z_index = 2
	else:
		# 离开时恢复原大小
		card.scale = Vector2(1, 1)
		# 恢复z轴层级
		card.z_index = 1 

# 射线检测：检查鼠标位置是否有卡片
func raycast_check_for_card():
	# 获取2D物理空间状态
	var space_state = get_world_2d().direct_space_state
	# 创建点查询参数
	var parameters = PhysicsPointQueryParameters2D.new()
	# 设置检测点为当前鼠标位置
	parameters.position = get_global_mouse_position()
	# 允许检测Area2D类型的碰撞体
	parameters.collide_with_areas = true
	# 只检测卡片碰撞层的对象
	parameters.collision_mask = COLLISION_MASK_CARD
	
	# 执行点查询，获取碰撞结果
	var result = space_state.intersect_point(parameters)
	
	# 如果有碰撞结果
	if result.size() > 0:
		# 返回z轴层级最高的卡片（解决卡片重叠问题）
		return get_card_with_highest_z_index(result)
	# 没有检测到卡片
	return null

# 射线检测：检查鼠标位置是否有卡槽
func raycast_check_for_card_solt():
	# 获取2D物理空间状态
	var space_state = get_world_2d().direct_space_state
	# 创建点查询参数
	var parameters = PhysicsPointQueryParameters2D.new()
	# 设置检测点为当前鼠标位置
	parameters.position = get_global_mouse_position()
	# 允许检测Area2D类型的碰撞体
	parameters.collide_with_areas = true
	# 只检测卡槽碰撞层的对象
	parameters.collision_mask = COLLISION_MASK_CARD_SOLT
	
	# 执行点查询，获取碰撞结果
	var result = space_state.intersect_point(parameters)
	
	# 如果有碰撞结果，返回卡槽节点（假设碰撞体是卡槽的子节点）
	if result.size() > 0:
		return result[0].collider.get_parent()
	# 没有检测到卡槽
	return null

# 从多个碰撞结果中获取z轴层级最高的卡片
# 解决多张卡片重叠时，只与最上层卡片交互的问题
func get_card_with_highest_z_index(card_results):
	# 假设第一个结果是层级最高的卡片
	var highest_z_card = card_results[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	# 循环检查所有碰撞结果，找到真正层级最高的卡片
	for i in range(1, card_results.size()):
		var current_card = card_results[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	
	return highest_z_card
