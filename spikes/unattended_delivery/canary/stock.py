class Stock:
    def __init__(self, counts):
        self.counts = counts

    def available(self, item):
        return self.counts.get(item, 0)

    def reserve(self, item, quantity):
        return False
