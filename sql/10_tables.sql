-- MySQL dump 10.13  Distrib 5.5.47, for debian-linux-gnu (x86_64)
--
-- Host: zeus    Database: atlas
-- ------------------------------------------------------
-- Server version	5.5.44-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `commlinks`
--

DROP TABLE IF EXISTS `commlinks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `commlinks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) DEFAULT '(unnamed)',
  `host1` int(11) NOT NULL,
  `host2` int(11) NOT NULL,
  `up` decimal(5,4) DEFAULT NULL,
  `node` int(11) DEFAULT NULL,
  `type` varchar(64) NOT NULL DEFAULT 'Unknown type',
  `speed` bigint(20) NOT NULL DEFAULT '1073741824',
  PRIMARY KEY (`id`),
  UNIQUE KEY `node` (`node`),
  KEY `host1` (`host1`),
  KEY `host2` (`host2`),
  CONSTRAINT `commlinks_ibfk_1` FOREIGN KEY (`host1`) REFERENCES `hosts` (`id`),
  CONSTRAINT `commlinks_ibfk_2` FOREIGN KEY (`host2`) REFERENCES `hosts` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `commlinks`
--

LOCK TABLES `commlinks` WRITE;
/*!40000 ALTER TABLE `commlinks` DISABLE KEYS */;
/*!40000 ALTER TABLE `commlinks` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`atlas`@`%`*/ /*!50003 TRIGGER after_commlink_update AFTER UPDATE ON commlinks
  FOR EACH ROW
  BEGIN
    IF (STATE(OLD.up) != STATE(NEW.up)) 
    THEN
      INSERT INTO statechanges (object_type, object_id, from_state, to_state) 
      VALUES ('commlink', NEW.id, STATE(OLD.up), STATE(NEW.up));
    END IF;
  END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `hostgroupmembers`
--

DROP TABLE IF EXISTS `hostgroupmembers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hostgroupmembers` (
  `host` int(11) NOT NULL,
  `hostgroup` int(11) NOT NULL,
  UNIQUE KEY `hostgroupmembers` (`host`,`hostgroup`),
  KEY `hostgroup` (`hostgroup`),
  CONSTRAINT `hostgroupmembers_ibfk_1` FOREIGN KEY (`host`) REFERENCES `hosts` (`id`),
  CONSTRAINT `hostgroupmembers_ibfk_2` FOREIGN KEY (`hostgroup`) REFERENCES `hostgroups` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hostgroupmembers`
--

LOCK TABLES `hostgroupmembers` WRITE;
/*!40000 ALTER TABLE `hostgroupmembers` DISABLE KEYS */;
/*!40000 ALTER TABLE `hostgroupmembers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hostgroups`
--

DROP TABLE IF EXISTS `hostgroups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hostgroups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `site` int(11) NOT NULL,
  `up` decimal(5,4) DEFAULT NULL,
  `node` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name_site` (`name`,`site`),
  UNIQUE KEY `node` (`node`),
  KEY `site` (`site`),
  CONSTRAINT `hostgroups_ibfk_1` FOREIGN KEY (`site`) REFERENCES `sites` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hostgroups`
--

LOCK TABLES `hostgroups` WRITE;
/*!40000 ALTER TABLE `hostgroups` DISABLE KEYS */;
/*!40000 ALTER TABLE `hostgroups` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`atlas`@`%`*/ /*!50003 TRIGGER after_hostgroup_update AFTER UPDATE ON hostgroups
  FOR EACH ROW
  BEGIN
    IF (STATE(OLD.up) != STATE(NEW.up)) 
    THEN
      INSERT INTO statechanges (object_type, object_id, from_state, to_state) 
      VALUES ('hostgroup', NEW.id, STATE(OLD.up), STATE(NEW.up));
    END IF;
  END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `hosts`
--

DROP TABLE IF EXISTS `hosts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `hosts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `ip` varchar(16) DEFAULT NULL,
  `site` int(11) NOT NULL,
  `x` int(11) DEFAULT NULL,
  `y` int(11) DEFAULT NULL,
  `up` decimal(5,4) DEFAULT NULL,
  `since` datetime DEFAULT NULL,
  `checked` datetime DEFAULT NULL,
  `alive` datetime DEFAULT NULL,
  `node` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `node` (`node`),
  KEY `ip` (`ip`),
  KEY `site` (`site`),
  CONSTRAINT `hosts_ibfk_1` FOREIGN KEY (`site`) REFERENCES `sites` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hosts`
--

LOCK TABLES `hosts` WRITE;
/*!40000 ALTER TABLE `hosts` DISABLE KEYS */;
/*!40000 ALTER TABLE `hosts` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`atlas`@`%`*/ /*!50003 TRIGGER before_host_insert BEFORE INSERT ON hosts
  FOR EACH ROW
  BEGIN
    IF (NEW.x IS NULL AND NEW.y IS NULL) 
    THEN
      SET NEW.x = 100 + RAND()*200;
      SET NEW.y = 100 + RAND()*200;
    END IF;
    IF (NEW.ip = '' OR NEW.ip = '0.0.0.0')
    THEN
      SET NEW.ip = NULL;
    END IF;
  END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`atlas`@`%`*/ /*!50003 TRIGGER before_host_update BEFORE UPDATE ON hosts
  FOR EACH ROW
  BEGIN
    IF (NEW.ip = '' OR NEW.ip = '0.0.0.0') 
    THEN
      SET NEW.ip = NULL;
    END IF;
  END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`atlas`@`%`*/ /*!50003 TRIGGER after_host_update AFTER UPDATE ON hosts
  FOR EACH ROW
  BEGIN
    IF (STATE(OLD.up) != STATE(NEW.up)) 
    THEN
      INSERT INTO statechanges (object_type, object_id, from_state, to_state) 
      VALUES ('host', NEW.id, STATE(OLD.up), STATE(NEW.up));
    END IF;
  END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `sitegroupmembers`
--

DROP TABLE IF EXISTS `sitegroupmembers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sitegroupmembers` (
  `site` int(11) NOT NULL,
  `sitegroup` int(11) NOT NULL,
  UNIQUE KEY `sitegroupmembers` (`site`,`sitegroup`),
  KEY `sitegroup` (`sitegroup`),
  CONSTRAINT `sitegroupmembers_ibfk_1` FOREIGN KEY (`site`) REFERENCES `sites` (`id`),
  CONSTRAINT `sitegroupmembers_ibfk_2` FOREIGN KEY (`sitegroup`) REFERENCES `sitegroups` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sitegroupmembers`
--

LOCK TABLES `sitegroupmembers` WRITE;
/*!40000 ALTER TABLE `sitegroupmembers` DISABLE KEYS */;
/*!40000 ALTER TABLE `sitegroupmembers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sitegroups`
--

DROP TABLE IF EXISTS `sitegroups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sitegroups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `up` decimal(5,4) DEFAULT NULL,
  `node` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `node` (`node`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sitegroups`
--

LOCK TABLES `sitegroups` WRITE;
/*!40000 ALTER TABLE `sitegroups` DISABLE KEYS */;
/*!40000 ALTER TABLE `sitegroups` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`atlas`@`%`*/ /*!50003 TRIGGER after_sitegroup_update AFTER UPDATE ON sitegroups
  FOR EACH ROW
  BEGIN
    IF (STATE(OLD.up) != STATE(NEW.up)) 
    THEN
      INSERT INTO statechanges (object_type, object_id, from_state, to_state) 
      VALUES ('sitegroup', NEW.id, STATE(OLD.up), STATE(NEW.up));
    END IF;
  END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `sites`
--

DROP TABLE IF EXISTS `sites`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sites` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `x` int(11) DEFAULT NULL,
  `y` int(11) DEFAULT NULL,
  `up` decimal(5,4) DEFAULT NULL,
  `node` int(11) DEFAULT NULL,
  `type` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  UNIQUE KEY `node` (`node`),
  KEY `type` (`type`),
  CONSTRAINT `sites_ibfk_1` FOREIGN KEY (`type`) REFERENCES `sitetypes` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sites`
--

LOCK TABLES `sites` WRITE;
/*!40000 ALTER TABLE `sites` DISABLE KEYS */;
/*!40000 ALTER TABLE `sites` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`atlas`@`%`*/ /*!50003 TRIGGER before_site_insert BEFORE INSERT ON sites
  FOR EACH ROW
  BEGIN
    IF (NEW.x IS NULL AND NEW.y IS NULL) 
    THEN
      SET NEW.x = 100 + RAND()*200;
      SET NEW.y = 100 + RAND()*200;
    END IF;
  END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = '' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`atlas`@`%`*/ /*!50003 TRIGGER after_site_update AFTER UPDATE ON sites
  FOR EACH ROW
  BEGIN
    IF (STATE(OLD.up) != STATE(NEW.up)) 
    THEN
      INSERT INTO statechanges (object_type, object_id, from_state, to_state) 
      VALUES ('site', NEW.id, STATE(OLD.up), STATE(NEW.up));
    END IF;
  END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `sitetypes`
--

DROP TABLE IF EXISTS `sitetypes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sitetypes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `icon` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sitetypes`
--

LOCK TABLES `sitetypes` WRITE;
/*!40000 ALTER TABLE `sitetypes` DISABLE KEYS */;
/*!40000 ALTER TABLE `sitetypes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `statechanges`
--

DROP TABLE IF EXISTS `statechanges`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `statechanges` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `changed` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `object_type` varchar(32) NOT NULL,
  `object_id` int(11) NOT NULL,
  `from_state` varchar(32) NOT NULL,
  `to_state` varchar(32) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `statechanges`
--

LOCK TABLES `statechanges` WRITE;
/*!40000 ALTER TABLE `statechanges` DISABLE KEYS */;
/*!40000 ALTER TABLE `statechanges` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2016-03-07 21:01:47
