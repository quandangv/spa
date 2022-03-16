extends Polygon2D

func set_points(points):
  self.polygon = points
  points.push_back(points[0])
  $outline.points = points
