srcs_metal_c = [
{% for t in target_c %}
	'{{ t }}',
{% endfor %}
]

srcs_metal_s = [
{% for t in target_s %}
	'{{ t }}',
{% endfor %}
]
