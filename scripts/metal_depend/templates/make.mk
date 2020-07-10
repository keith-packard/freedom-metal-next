TARGET_C = {% for t in target_c %}\
        {{ t }} {% endfor %}


TARGET_S = {% for t in target_s %}\
        {{ t }}{% endfor %}


TARGET_C_VPATH = {{ target_c_dir|join(':') }}
TARGET_S_VPATH = {{ target_s_dir|join(':') }}

FEATURE_DEFINES ={% for f in feature_defines %} {{ f }}{% endfor %}
