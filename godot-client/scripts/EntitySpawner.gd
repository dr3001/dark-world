extends Node3D

# Dark World — Entity Spawner
# Cria placeholders visuais para entidades do servidor

var dragon_mesh_scene: PackedScene
var player_mesh_scene: PackedScene
var territory_mesh_scene: PackedScene

func _ready():
	# Criar mesh placeholder para dragão (cubo grande vermelho)
	var dragon_mesh = BoxMesh.new()
	dragon_mesh.size = Vector3(10, 5, 10)
	var dragon_mat = StandardMaterial3D.new()
	dragon_mat.albedo_color = Color(0.6, 0.1, 0.1)  # Vermelho escuro
	dragon_mat.emission = Color(0.3, 0.05, 0.05)
	dragon_mat.emission_enabled = true
	
	# Criar mesh para território
	var territory_mesh = BoxMesh.new()
	territory_mesh.size = Vector3(20, 0.2, 20)
	var territory_mat = StandardMaterial3D.new()
	territory_mat.albedo_color = Color(0.2, 0.3, 0.2)  # Verde escuro
	territory_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	territory_mat.albedo_color.a = 0.3

func spawn_entity(entity: Dictionary):
	var mesh_instance = MeshInstance3D.new()
	var entity_type = entity.get("entity_type", "")
	var pos_x = float(entity.get("position_x", 0)) / 10.0
	var pos_z = float(entity.get("position_y", 0)) / 10.0
	
	if entity_type == "dragon":
		var box = BoxMesh.new()
		box.size = Vector3(10, 5, 10)
		mesh_instance.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.1, 0.1)
		mesh_instance.set_surface_override_material(0, mat)
		mesh_instance.position = Vector3(pos_x, 2.5, pos_z)
		mesh_instance.name = "Dragon_" + entity.get("name", "Vorak")
		add_child(mesh_instance)
		
		# Label para o dragão
		var label = Label3D.new()
		label.text = entity.get("name", "Vorak") + "\n[AMEACA LETAL]"
		label.position = Vector3(0, 6, 0)
		label.modulate = Color(1, 0.2, 0.2)
		mesh_instance.add_child(label)
		
	elif entity_type == "player_character":
		# Jogador: cilindro azul
		var cyl = CylinderMesh.new()
		cyl.height = 2
		cyl.radius = 0.5
		mesh_instance.mesh = cyl
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.3, 0.8)
		mesh_instance.set_surface_override_material(0, mat)
		mesh_instance.position = Vector3(pos_x, 1, pos_z)
		mesh_instance.name = "Player_" + entity.get("name", "Heroi")
		add_child(mesh_instance)
		
	elif entity_type == "territory":
		var plane = PlaneMesh.new()
		plane.size = Vector2(20, 20)
		mesh_instance.mesh = plane
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.15, 0.25, 0.15, 0.5)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh_instance.set_surface_override_material(0, mat)
		mesh_instance.position = Vector3(pos_x, 0.05, pos_z)
		mesh_instance.name = "Territory_" + entity.get("name", "")
		add_child(mesh_instance)
