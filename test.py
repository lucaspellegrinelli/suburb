import redis

# Connect to the Redis server
r = redis.Redis(host='localhost', port=6379, db=0)

# Initialize the cursor
cursor = 0
queue_keys = []

# Iterate over the keyspace
while True:
    cursor, keys = r.scan(cursor=cursor, match='queue:*')
    queue_keys.extend(keys)
    if cursor == 0:
        break

# Print the queue names
for key in queue_keys:
    print(key.decode('utf-8'))
