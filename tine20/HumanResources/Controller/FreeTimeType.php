<?php
/**
 * FreeTimeType controller for HumanResources application
 *
 * @package     HumanResources
 * @subpackage  Controller
 * @license     http://www.gnu.org/licenses/agpl.html AGPL Version 3
 * @author      Paul Mehrer <p.mehrer@metaways.de>
 * @copyright   Copyright (c) 2019-2021 Metaways Infosystems GmbH (http://www.metaways.de)
 *
 */

/**
 * FreeTimeType controller class for HumanResources application
 *
 * @package     HumanResources
 * @subpackage  Controller
 */
class HumanResources_Controller_FreeTimeType extends Tinebase_Controller_Record_Abstract
{
    use Tinebase_Controller_SingletonTrait;

    /**
     * the constructor
     *
     * don't use the constructor. use the singleton
     */
    protected function __construct()
    {
        $this->_applicationName = HumanResources_Config::APP_NAME;
        $this->_backend = new Tinebase_Backend_Sql([
            Tinebase_Backend_Sql_Abstract::MODEL_NAME => HumanResources_Model_FreeTimeType::class,
            Tinebase_Backend_Sql_Abstract::TABLE_NAME => HumanResources_Model_FreeTimeType::TABLE_NAME,
            Tinebase_Backend_Sql_Abstract::MODLOG_ACTIVE => true,
        ]);
        $this->_modelName = HumanResources_Model_FreeTimeType::class;
        $this->_purgeRecords = false;
        $this->_doContainerACLChecks = false;
    }

    /**
     * @param HumanResources_Model_FreeTimeType $_record
     * @param HumanResources_Model_FreeTimeType $_oldRecord
     */
    protected function _inspectBeforeUpdate($_record, $_oldRecord)
    {
        if ($_oldRecord->system || $_record->system) {
            throw new Tinebase_Exception_Record_NotAllowed('system fields may not be updated');
        }

        parent::_inspectBeforeUpdate($_record, $_oldRecord);
    }

    protected function _inspectDelete(array $_ids)
    {
        if ($this->getMultiple($_ids)->filter('system', true)->count() > 0) {
            throw new Tinebase_Exception_Record_NotAllowed('system fields may not be deleted');
        }
        return parent::_inspectDelete($_ids);
    }
}
