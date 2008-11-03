<?php
/**
 * Tine 2.0 - http://www.tine20.org
 * 
 * @package     Erp
 * @license     http://www.gnu.org/licenses/agpl.html
 * @copyright   Copyright (c) 2008 Metaways Infosystems GmbH (http://www.metaways.de)
 * @author      Philipp Schuele <p.schuele@metaways.de>
 * @version     $Id$
 * 
 */

/**
 * Test helper
 */
require_once dirname(dirname(dirname(__FILE__))) . DIRECTORY_SEPARATOR . 'TestHelper.php';

if (!defined('PHPUnit_MAIN_METHOD')) {
    define('PHPUnit_MAIN_METHOD', 'Erp_Backend_NumberTest::main');
}

/**
 * Test class for Erp_Backend_NumberTest
 */
class Erp_Backend_NumberTest extends PHPUnit_Framework_TestCase
{
    
    /**
     * the project backend
     *
     * @var Erp_Backend_Number
     */
    protected $_backend;
    
    /**
     * Runs the test methods of this class.
     */
    public static function main()
    {
		$suite  = new PHPUnit_Framework_TestSuite('Tine 2.0 Erp Number Backend Tests');
        PHPUnit_TextUI_TestRunner::run($suite);
	}

    /**
     * Sets up the fixture.
     * 
     * This method is called before a test is executed.
     */
    protected function setUp()
    {
        $this->_backend = new Erp_Backend_Number();
    }

    /**
     * Tears down the fixture
     * This method is called after a test is executed.
     *
     */
    protected function tearDown()
    {
    }
    
    /**
     * get next number
     *
     */
    public function testGetNextNumber()
    {
        $userId = Tinebase_Core::getUser()->getId();
        $number = $this->_backend->getNext(Erp_Model_Number::TYPE_PROJECT, $userId);
        
        $nextNumber = $this->_backend->getNext(Erp_Model_Number::TYPE_PROJECT, $userId);
        
        $this->assertEquals($number->number+1, $nextNumber->number);
        $this->assertEquals($number->type, $nextNumber->type);
        
        // reset or delete old number
        if ($number->number == 1) {
            $this->_backend->delete($number);
        } else {
            $number->number--;
            $this->_backend->update($number);
        }
    }
}
