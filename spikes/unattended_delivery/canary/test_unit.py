import unittest
from stock import Stock


class StockTest(unittest.TestCase):
    def test_initial_count(self):
        self.assertEqual(Stock({'tea': 5}).available('tea'), 5)
