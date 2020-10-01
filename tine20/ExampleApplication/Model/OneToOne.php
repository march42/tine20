<?php
/**
 * class to hold OneToOne example record data
 *
 * @package     ExampleApplication
 * @subpackage  Model
 * @license     http://www.gnu.org/licenses/agpl.html AGPL Version 3
 * @author      Paul Mehrer <p.mehrer@metaways.de>
 * @copyright   Copyright (c) 2020 Metaways Infosystems GmbH (http://www.metaways.de)
 *
 */

use Doctrine\ORM\Mapping\ClassMetadataInfo;

/**
 * class to hold OneToOne example record data
 *
 * @package     ExampleApplication
 * @subpackage  Model
 * @property Tinebase_DateTime datetime
 */
class ExampleApplication_Model_OneToOne extends Tinebase_Record_NewAbstract
{
    const FLD_EXAMPLE_RECORD = 'example_record';
    const FLD_NAME = 'name';

    const MODEL_NAME_PART = 'OneToOne';
    const TABLE_NAME = 'example_onetoone';

    /**
     * holds the configuration object (must be declared in the concrete class)
     *
     * @var Tinebase_ModelConfiguration
     */
    protected static $_configurationObject = NULL;

    /**
     * Holds the model configuration (must be assigned in the concrete class)
     *
     * @var array
     */
    protected static $_modelConfiguration = [
        self::VERSION                   => 1,
        self::APP_NAME                  => ExampleApplication_Config::APP_NAME,
        self::MODEL_NAME                => self::MODEL_NAME_PART,
        self::IS_DEPENDENT              => true,
        self::MODLOG_ACTIVE             => true,

        self::TABLE                     => [
            self::NAME                      => self::TABLE_NAME,
            self::UNIQUE_CONSTRAINTS        => [
                self::FLD_EXAMPLE_RECORD        => [
                    self::COLUMNS                   => [self::FLD_EXAMPLE_RECORD]
                ]
            ]
        ],

        self::ASSOCIATIONS => [
            // this morphs into a one_to_one since example_record is unique too
            ClassMetadataInfo::MANY_TO_ONE  => [
                self::FLD_EXAMPLE_RECORD        => [
                    self::TARGET_ENTITY             => ExampleApplication_Model_ExampleRecord::class,
                    self::FIELD_NAME                => self::FLD_EXAMPLE_RECORD,
                    self::JOIN_COLUMNS              => [[
                        self::NAME                      => self::FLD_EXAMPLE_RECORD,
                        self::REFERENCED_COLUMN_NAME    => 'id',
                        self::ON_DELETE                 => 'CASCADE',
                    ]],
                ]
            ],
        ],

        self::FIELDS                    => [
            self::FLD_NAME                  => [
                self::TYPE                      => self::TYPE_STRING,
                self::LENGTH                    => 255,
                self::VALIDATORS                => [
                    Zend_Filter_Input::ALLOW_EMPTY  => false,
                    Zend_Filter_Input::PRESENCE     => Zend_Filter_Input::PRESENCE_REQUIRED,
                ],
                self::LABEL                     => 'Name', // _('Name')
                self::QUERY_FILTER              => true,
            ],
            self::FLD_EXAMPLE_RECORD        => [
                self::TYPE                      => self::TYPE_RECORD,
                self::LENGTH                    => 40,
                self::VALIDATORS                => [
                    Zend_Filter_Input::ALLOW_EMPTY => false,
                    Zend_Filter_Input::PRESENCE => Zend_Filter_Input::PRESENCE_REQUIRED
                ],
                self::CONFIG                    => [
                    self::APP_NAME                  => ExampleApplication_Config::APP_NAME,
                    self::MODEL_NAME                => ExampleApplication_Model_ExampleRecord::MODEL_NAME_PART,
                    self::IS_DEPENDENT              => true, // TODO do we need this?
                ]
            ],
        ]
    ];
}
