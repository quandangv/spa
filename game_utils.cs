using Godot;
using System.Collections.Generic;
using System;

public class game_utils : Node
{
  [Export] public Dictionary<String, Color> ship_colors;
  [Export] public Dictionary<String, Color> plasma_colors;
  public List<Node> ship_inputs = new List<Node>();
  public Node camera_input;
  
  public override void _Ready()
  {
    GD.Randomize();
  }
  
  void connect_exit(string signal, Node arg) {
    arg.Connect("tree_exiting", this, signal, new Godot.Collections.Array {arg});
  }
  public bool register_camera_input(Node holder) {
    if (camera_input == null) {
      connect_exit("unregister_camera_input", holder);
      camera_input = holder;
      if (ship_inputs.Count == 0)
        return true;
    }
    holder.Call("lost_input");
    return false;
  }
  public void unregister_camera_input(Node holder) {
    if (holder == camera_input)
      camera_input = null;
  }
  
  public bool register_ship_input(Node holder) {
    var i = ship_inputs.IndexOf(holder);
    if (i >= 0)
      return i == 0;
    ship_inputs.Add(holder);
    connect_exit("unregister_ship_input", holder);
    if (ship_inputs.Count == 1) {
      if (camera_input != null)
        camera_input.Call("lost_input");
      return true;
    }
    return false;
  }
  public void unregister_ship_input(Node holder) {
    var i = ship_inputs.IndexOf(holder);
    if (i >= 0) {
      ship_inputs.RemoveAt(i);
      if (ship_inputs.Count == 0) {
        if (camera_input != null)
          camera_input.Call("gained_input");
      } else if (i == 0) {
        ship_inputs[0].Call("gained_input");
      }
    }
  }
  
  public bool is_enemy(String side, Node other) {
    var other_side = other.Get("side");
    return other_side != null && !other_side.Equals("junk") && !other_side.Equals(side);
  }
  
  /// Calculate the direction to move to dodge the specified projectiles
  /// - pos, speed: the state of our ship
  /// - sqr_gap: only try to dodge projectiles that would come within this gap to our ship
  /// - projectiles: list of projectiles
  /// - max_check: maximum number of projectiles to consider, used to improve performance at the cost of accuracy
  public Vector2 dodge_projectiles(Vector2 pos, Vector2 speed, float sqr_gap, Node2D[] projectiles, int max_check) {
    List<Node2D> removed; // List to store projectiles that don't pose a risk to our ship
    if (max_check > projectiles.Length) {
      max_check = projectiles.Length;
      removed = new List<Node2D>(0);
    } else {
      removed = new List<Node2D>(Mathf.Min(projectiles.Length - max_check, max_check)); // The capacity will be the smaller of the number of checked projectiles and the number of projectiles left unchecked
    }
    var total = Vector2.Zero; // The sum of results calculated from each of the contributing projectile
    var count = 0; // Number of contributing projectile to calculate the average
    for (int i = 0; i < max_check; i++) {
      // Formula to calculate the approach time, the time that the projectile reaches nearest to our ship
      var diff = (Vector2)projectiles[i].GlobalPosition - pos;
      var vdiff = (Vector2)projectiles[i].Get("linear_velocity") - speed;
      if (Mathf.Abs(vdiff.x) + Mathf.Abs(vdiff.y) < 0.0001) continue; // Projectile not moving relative to us, will take forever to reach
      float approach_time = - vdiff.Dot(diff) / vdiff.LengthSquared();
      if (approach_time > 0) { // Skips the case of approach_time <= 0, ie. the projectile is moving away from us
        var approach_diff = diff + vdiff * approach_time; // The difference vector when the projectile is nearest to our ship, this is the resulting vector of the projectile
        var sqr_length = approach_diff.LengthSquared();
        if (sqr_length < sqr_gap) {
          if (approach_time <= 2) { // Also skip the case when the projectile is still far away, so that we can focus on dodging urgent ones
            count++;
            total += approach_diff / approach_time;
          }
          continue;
        }
      }
      // Mark projectiles that have moved pass or would not come near us to be moved to the back so that we are less likely to check them again in the future
      if (removed.Count < removed.Capacity) { // We would not move more than the number of projectiles left unchecked, as moving them to the back would still leave them inside the max_check range
        removed.Add(projectiles[i]);
        projectiles[i] = null;
      }
    }
    // Compact our projectile array to leave empty spaces at the back
    for (int i = 0, delta = 0; i < projectiles.Length; i++) {
      if (projectiles[i] == null)
        delta++;
      else if (delta > 0)
        projectiles[i-delta] = projectiles[i];
    }
    // Add the removed projectiles back to the array
    for (int i = 0; i < removed.Count; i++)
      projectiles[projectiles.Length - i - 1] = removed[i];
    return count > 0 ? total / count : total;
  }
  
  public double erf(double x) {
    // constants
    double a1 = 0.254829592;
    double a2 = -0.284496736;
    double a3 = 1.421413741;
    double a4 = -1.453152027;
    double a5 = 1.061405429;
    double p = 0.3275911;
    // Save the sign of x
    int sign = 1;
    if (x < 0)
        sign = -1;
    x = Math.Abs(x);
    // A&S formula 7.1.26
    double t = 1.0 / (1.0 + p*x);
    double y = 1.0 - (((((a5*t + a4)*t) + a3)*t + a2)*t + a1)*t*Math.Exp(-x*x);
    return sign*y;
  }
  
  /// Calculate aim rotation for a direction, taking into account ship and bullet speed
  public float moving_aim(Vector2 velocity, Vector2 direction, float bullet_speed) {
    var speed = velocity.Length();
    var naive_angle = direction.Angle();
    return naive_angle - Mathf.Asin(Mathf.Clamp(Mathf.Sin(velocity.Angle() - naive_angle) * speed / bullet_speed, -1, 1));
  }
  
  /// Extrapolate the position of a target when our bullets reach it, assuming our ship is at origin
  /// - position, velocity, accel: the state of the target to calculate its trajectory
  /// - bullet_speed, ship_velocity: used to calculate the bullet speed toward the target, thus the time to reach
  ///   We need the ship speed because bullet speed is relative to the ship, not the global
  public Vector2 extrapolate(Vector2 position, Vector2 velocity, Vector2 accel, float bullet_speed, Vector2 ship_velocity) {
    var result = position;
    bullet_speed += position.Normalized().Dot(ship_velocity);
    float bullet_speed_sqr = bullet_speed * bullet_speed;
    /// Calculate the position of the target after the time for our bullet to reach the *current* extrapolation
    /// This would not be 100% accurate, because the time to reach the new extrapolation would be different from that of the old extrapolation
    /// Ideally we would repeat this step many times, until the time values converge
    void extrapolate_step() {
      var time_sqr = result.LengthSquared() / bullet_speed_sqr;
      result = position + velocity * Mathf.Sqrt(time_sqr) + accel * time_sqr / 2;
    }
    bullet_speed_sqr /= 1.5f; // As we only run the extrapolation step twice, compensate by a fixed ratio
    extrapolate_step();
    extrapolate_step();
    if (result.Dot(position) < 0) // Don't interpolate at all if it tells us to fire away from the target
      return position;
    return result;
  }
}
 
