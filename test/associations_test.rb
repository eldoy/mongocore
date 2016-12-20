test 'Associations'

# Belong




# Many




# Example YML:
# active:
#   $or:
#     user_id: $user.id
#     listener: $user.id
#     listener: $user.link
#   deletors:
#     $ne: $user.id
