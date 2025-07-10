import dns.resolver
import time
import random

domains = ["demo.gslb.maniak.lab", "juice.gslb.maniak.lab"]
dns_server = "172.16.20.53"
resolver = dns.resolver.Resolver()
resolver.nameservers = [dns_server]

end_time = time.time() + 24 * 3600  # 24 hours in seconds

while time.time() < end_time:
    queries = random.randint(10, 100)
    for _ in range(queries):
        domain = random.choice(domains)
        try:
            answers = resolver.resolve(domain, "A")
            for rdata in answers:
                print(f"{domain}: {rdata.address}")
        except Exception as e:
            print(f"Error querying {domain}: {e}")
    time.sleep(random.uniform(0.1, 1.0))  # Random delay between batches