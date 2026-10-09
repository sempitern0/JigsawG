extends RefCounted
## Pure connected-components model. The dragged group's root survives a merge.
## Membership queries return copies; callers cannot mutate internal arrays.

var _parents: Array[int] = []
var _members: Dictionary = {}


func reset(piece_count: int) -> void:
	clear()
	for id in range(maxi(0, piece_count)):
		_parents.append(id)
		_members[id] = [id]


func clear() -> void:
	_parents.clear()
	_members.clear()


func piece_count() -> int:
	return _parents.size()


func group_count() -> int:
	return _members.size()


func root_of(piece_id: int) -> int:
	return _parents[piece_id] if piece_id >= 0 and piece_id < _parents.size() else -1


func same_group(first_id: int, second_id: int) -> bool:
	var first_root := root_of(first_id)
	return first_root >= 0 and first_root == root_of(second_id)


func members_for(piece_id: int) -> PackedInt32Array:
	return members_of_root(root_of(piece_id))


func members_of_root(root: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	if root < 0 or root >= _parents.size() or _parents[root] != root:
		return result
	for member in _members.get(root, []):
		result.append(int(member))
	return result


func group_ids() -> PackedInt32Array:
	var result := PackedInt32Array()
	for root in _parents:
		result.append(root)
	return result


## Atomic: invalid IDs or non-self-representative roots leave the model intact.
func restore(group_ids: PackedInt32Array) -> bool:
	var next_parents: Array[int] = []
	var next_members: Dictionary = {}
	var count := group_ids.size()
	for piece_id in range(count):
		var root: int = group_ids[piece_id]
		if root < 0 or root >= count:
			return false
		next_parents.append(root)
		if not next_members.has(root):
			next_members[root] = []
		next_members[root].append(piece_id)
	for root in next_members:
		if next_parents[int(root)] != int(root):
			return false
	_parents = next_parents
	_members = next_members
	return true


## Return only newly joined members (empty for invalid or repeated joins).
func merge(anchor_piece_id: int, neighbor_piece_id: int) -> PackedInt32Array:
	var joined := PackedInt32Array()
	var target := root_of(anchor_piece_id)
	var source := root_of(neighbor_piece_id)
	if target < 0 or source < 0 or target == source:
		return joined
	var target_members: Array = _members[target]
	for member_variant in _members[source]:
		var member := int(member_variant)
		_parents[member] = target
		target_members.append(member)
		joined.append(member)
	_members[target] = target_members
	_members.erase(source)
	return joined
