"""One selected domain-boundary acceptance example, controller-protected."""
import unittest
from stock import Stock


class ReservationExample(unittest.TestCase):
    def test_reserve_then_refuse_oversell(self):
        stock = Stock({'tea': 5})
        self.assertIs(stock.reserve('tea', 2), True)
        self.assertEqual(stock.available('tea'), 3)
        with self.assertRaises(ValueError):
            stock.reserve('tea', 4)
        self.assertEqual(stock.available('tea'), 3)
