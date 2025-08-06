# 卡牌交互管理器
# 核心职责：统一处理卡牌的拖拽逻辑、悬停高亮效果、以及卡牌向卡槽的放置判断
extends Node2D

# 碰撞掩码常量 - 用于2D物理系统中区分不同类型对象的碰撞检测（通过位运算过滤）
const COLLISION_MASK_CARD = 1         # 卡牌碰撞层的掩码值（仅检测卡牌类型碰撞体）
const COLLISION_MASK_CARD_SOLT = 2    # 卡槽碰撞层的掩码值（仅检测卡槽类型碰撞体）
const DEFAULT_CARD_MOVE_SPEED = 0.1   # 卡牌移动（如放回手牌）的默认动画速度

# 变量定义
var screen_size                       # 存储屏幕尺寸向量，用于限制卡牌拖拽范围（防止拖出屏幕外）
var card_being_dragged                # 跟踪当前正在被拖拽的卡牌节点（null表示无拖拽）
var is_hovering_on_card = false       # 状态标记：是否有卡牌正被鼠标悬停（用于高亮逻辑互斥）
var player_hand_reference             # 玩家手牌容器节点的引用（用于卡牌回收、排列等管理）

# 节点就绪时调用（初始化逻辑）
func _ready() -> void:
	# 获取当前视图（游戏窗口）的尺寸，用于后续限制卡牌移动范围
	screen_size = get_viewport_rect().size
	# 获取玩家手牌容器的引用（路径需根据实际场景结构调整，确保能正确找到手牌节点）
	player_hand_reference = $"../PlayerHand"
	# 连接输入管理器的鼠标左键释放信号到本节点的处理函数（响应拖拽结束）
	$"../InputManager".connect("left_mouse_button_released", on_left_click_released)


# 每帧更新回调（处理实时交互逻辑）
func _process(delta: float) -> void:
	# 如果存在正在拖拽的卡牌，实时更新其位置跟随鼠标
	if card_being_dragged:
		# 获取鼠标在全局坐标系中的位置（相对于游戏世界）
		var mouse_pos = get_global_mouse_position()
		# 限制卡牌移动范围在屏幕内（使用clamp函数约束x、y轴坐标）
		card_being_dragged.position = Vector2(
			clamp(mouse_pos.x, 0, screen_size.x),  # x轴限制在0到屏幕宽度之间
			clamp(mouse_pos.y, 0, screen_size.y)   # y轴限制在0到屏幕高度之间
		)


# 开始拖拽卡牌的处理函数（通常由卡牌的点击事件触发）
func start_drag(card):
	# 记录当前被拖拽的卡牌节点
	card_being_dragged = card
	# 拖拽时恢复卡牌默认大小（取消悬停状态的放大效果，避免拖拽中尺寸异常）
	card.scale = Vector2(1, 1)

# 结束卡牌拖拽，处理放置逻辑（鼠标释放时调用）
func finish_drag():
	# 结束拖拽时恢复悬停放大效果（为下次悬停做准备）
	card_being_dragged.scale = Vector2(1.05, 1.05)
	
	# 通过射线检测判断鼠标释放位置是否有可用卡槽
	var card_slot_found = raycast_check_for_card_solt()
	
	# 如果找到卡槽且该卡槽为空（未放置卡牌）
	if card_slot_found and not card_slot_found.card_in_slot:
		# 从玩家手牌中移除该卡牌（更新手牌数据和布局）
		player_hand_reference.remove_card_from_hand(card_being_dragged)
		# 将卡牌移动到卡槽位置（视觉上放置到卡槽）
		card_being_dragged.position = card_slot_found.position
		# 禁用卡牌的碰撞体（防止放置后再次被选中拖拽）
		card_being_dragged.get_node("Area2D/CollisionShape2D").disabled = true
		# 标记卡槽为已占用（更新卡槽状态，防止重复放置）
		card_slot_found.card_in_slot = true
	else:
		# 未找到有效卡槽，将卡牌放回手牌（通过手牌管理器重新排列）
		player_hand_reference.add_card_to_hand(card_being_dragged, DEFAULT_CARD_MOVE_SPEED)
	
	# 清除拖拽状态（结束本轮拖拽）
	card_being_dragged = null

# 连接卡牌的悬停信号（需在卡牌创建时调用，建立信号与处理函数的关联）
func connect_card_signal(card):
	# 连接卡牌的"hovered"信号到本节点的悬停处理函数
	card.connect("hovered", on_hovered_over_card)
	# 连接卡牌的"hovered_off"信号到本节点的离开悬停处理函数
	card.connect("hovered_off", on_hovered_off_card)

# 响应鼠标左键释放事件（触发拖拽结束逻辑）
func on_left_click_released():
	# 如果有卡牌正在被拖拽，执行结束拖拽逻辑
	if card_being_dragged:
		finish_drag()

# 鼠标悬停在卡牌上时的处理逻辑
func on_hovered_over_card(card):
	# 如果当前没有其他卡牌被悬停（避免多卡牌同时高亮的冲突）
	if !is_hovering_on_card:
		is_hovering_on_card = true  # 更新悬停状态
		highlight_card(card, true)  # 对当前卡牌执行高亮效果

# 鼠标离开卡牌时的处理逻辑
func on_hovered_off_card(card):
	# 如果没有卡牌正在被拖拽（拖拽状态下不处理离开悬停，避免视觉闪烁）
	if !card_being_dragged:
		highlight_card(card, false)  # 取消当前卡牌的高亮效果
		# 检测鼠标是否移动到了另一张卡牌上（处理连续悬停的平滑过渡）
		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered:
			# 对新悬停的卡牌执行高亮
			highlight_card(new_card_hovered, true)
		else:
			# 没有悬停任何卡牌，重置悬停状态
			is_hovering_on_card = false

# 卡牌高亮效果处理（视觉反馈：缩放+层级调整）
func highlight_card(card, hovered):
	if hovered == true:
		# 悬停时放大卡牌（1.05倍缩放，增强视觉焦点）
		card.scale = Vector2(1.05, 1.05)
		# 提高z轴层级（确保悬停卡牌显示在其他卡牌上方，避免被遮挡）
		card.z_index = 2
	else:
		# 离开悬停时恢复原大小
		card.scale = Vector2(1, 1)
		# 恢复默认z轴层级
		card.z_index = 1 

# 射线检测：判断鼠标位置是否有卡牌（用于悬停切换检测）
func raycast_check_for_card():
	# 获取2D物理空间的状态（用于执行碰撞检测）
	var space_state = get_world_2d().direct_space_state
	# 创建点查询参数（检测指定点上的碰撞体）
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()  # 检测点设为当前鼠标位置
	parameters.collide_with_areas = true  # 允许检测Area2D类型的碰撞体（卡牌通常用Area2D检测交互）
	parameters.collision_mask = COLLISION_MASK_CARD  # 仅检测卡牌碰撞层的对象
	
	# 执行点查询，返回所有碰撞结果（数组）
	var result = space_state.intersect_point(parameters)
	
	# 如果有碰撞结果，返回层级最高的卡牌（解决卡牌重叠时的交互优先级）
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	# 无碰撞结果，返回null
	return null

# 射线检测：判断鼠标位置是否有卡槽（用于放置卡牌时的有效性判断）
func raycast_check_for_card_solt():
	# 获取2D物理空间状态
	var space_state = get_world_2d().direct_space_state
	# 创建点查询参数
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()  # 检测点为当前鼠标位置
	parameters.collide_with_areas = true  # 允许检测Area2D（卡槽通常用Area2D作为碰撞区域）
	parameters.collision_mask = COLLISION_MASK_CARD_SOLT  # 仅检测卡槽碰撞层的对象
	
	# 执行点查询，获取碰撞结果
	var result = space_state.intersect_point(parameters)
	
	# 如果有碰撞结果，返回卡槽节点（假设碰撞体是卡槽的子节点，通过get_parent()获取卡槽本身）
	if result.size() > 0:
		return result[0].collider.get_parent()
	# 无卡槽，返回null
	return null

# 从多个碰撞结果中筛选出z轴层级最高的卡牌（解决卡牌重叠时的交互目标问题）
func get_card_with_highest_z_index(card_results):
	# 初始假设第一个结果是层级最高的卡牌（碰撞结果可能按距离排序，不一定是z轴）
	var highest_z_card = card_results[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	# 遍历所有碰撞结果，找到真正z轴层级最高的卡牌
	for i in range(1, card_results.size()):
		var current_card = card_results[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	
	return highest_z_card
