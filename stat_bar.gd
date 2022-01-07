extends ProgressBar

func set_value(value):
	self.value = value
	$value.text = str(value)
