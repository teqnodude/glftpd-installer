CREATE TABLE IF NOT EXISTS `trial` ( 
`active` tinyint(1) default NULL, 
`username` text NOT NULL, 
`stats` text NOT NULL, 
`added` text NOT NULL, 
`extratime` text, 
`startstats` text NOT NULL, 
`endtime` text NOT NULL, 
`tlimit` text NOT NULL ) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `excluded` ( 
`username` text NOT NULL, 
`excluded` tinyint(1) NOT NULL default '0' ) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `passed` ( 
`username` text NOT NULL, 
`passed` tinyint(1) NOT NULL default '0' ) ENGINE=MyISAM DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `ranking` ( 
`username` text NOT NULL, `rank` text NOT NULL ) ENGINE=MyISAM DEFAULT CHARSET=latin1;
