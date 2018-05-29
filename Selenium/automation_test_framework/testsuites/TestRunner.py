# coding = utf-8
import unittest

suite = unittest.TestLoader().discover("testsuites")


if __name__=='__main__':
    #执行用例
    runner=unittest.TextTestRunner()
    runner.run(suite)