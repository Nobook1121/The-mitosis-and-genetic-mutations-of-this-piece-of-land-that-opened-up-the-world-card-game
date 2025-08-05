# 卡牌逻辑脚本，继承自Node2D（2D节点，可包含 Sprite、Area2D 等子节点实现卡牌视觉和交互）
extends Node2D

# 定义信号：当鼠标悬停在卡牌上时发射
signal hovered     # 悬停信号，携带当前卡牌实例作为参数
# 定义信号：当鼠标离开卡牌时发射
signal hovered_off # 取消悬停信号，携带当前卡牌实例作为参数

# 存储卡牌在玩家手牌中的位置信息（可能用于布局排列、移动动画等）
var hand_position

# 节点就绪时调用（节点及其子节点加载完成后执行）
func _ready() -> void:
	# 调用父节点的connect_card_signal方法，将当前卡牌实例传递给父节点
	# 作用：让父节点（通常是手牌管理器）连接当前卡牌的信号，统一处理交互逻辑
	get_parent().connect_card_signal(self)

# Area2D节点检测到鼠标进入时的回调函数（需在编辑器中与Area2D的mouse_entered信号绑定）
func _on_area_2d_mouse_entered() -> void:
	# 发射hovered信号，通知监听者（如手牌管理器）当前卡牌被悬停
	emit_signal("hovered", self)


# Area2D节点检测到鼠标退出时的回调函数（需在编辑器中与Area2D的mouse_exited信号绑定）
func _on_area_2d_mouse_exited() -> void:
	# 发射hovered_off信号，通知监听者当前卡牌的悬停状态已取消
	emit_signal("hovered_off", self)
