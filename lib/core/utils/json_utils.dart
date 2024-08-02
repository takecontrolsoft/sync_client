bool compareJson(dynamic json, dynamic otherJson) {
  // Check if the types of the objects are the same
  if (json.runtimeType != otherJson.runtimeType) {
    return false;
  }

  // Compare same keys
  if (json is Map<String, dynamic> && otherJson is Map<String, dynamic>) {
    if (!json.keys.toSet().containsAll(otherJson.keys.toSet()) ||
        !otherJson.keys.toSet().containsAll(json.keys.toSet())) {
      return false;
    }

    // Recursively compare the values for each key
    for (var key in json.keys) {
      if (!compareJson(json[key], otherJson[key])) {
        return false;
      }
    }
    return true;
  }

  // Compare lists lengths
  if (json is List<dynamic> && otherJson is List<dynamic>) {
    if (json.length != otherJson.length) {
      return false;
    }

    // Recursively compare the values at each index
    for (var i = 0; i < json.length; i++) {
      if (!compareJson(json[i], otherJson[i])) {
        return false;
      }
    }
    return true;
  }

  // Compare other types of values
  return json == otherJson;
}
