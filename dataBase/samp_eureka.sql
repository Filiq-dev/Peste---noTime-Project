-- phpMyAdmin SQL Dump
-- version 4.6.6
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: 10 Ian 2019 la 17:35
-- Versiune server: 10.1.37-MariaDB
-- PHP Version: 7.0.32

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `samp_eureka`
--

-- --------------------------------------------------------

--
-- Structura de tabel pentru tabelul `accounts_blocked`
--

CREATE TABLE `accounts_blocked` (
  `id` int(11) NOT NULL,
  `playerID` int(13) NOT NULL,
  `time` varchar(10) NOT NULL,
  `securityCode` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Structura de tabel pentru tabelul `bans`
--

CREATE TABLE `bans` (
  `id` int(11) NOT NULL,
  `playerID` int(11) NOT NULL,
  `bannedBy` varchar(25) NOT NULL,
  `SerialCode` varchar(41) NOT NULL,
  `time` int(11) NOT NULL,
  `reason` varchar(50) NOT NULL,
  `ip` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Structura de tabel pentru tabelul `cars`
--

CREATE TABLE `cars` (
  `id` int(11) NOT NULL,
  `Model` int(3) NOT NULL DEFAULT '400',
  `Group` int(3) NOT NULL DEFAULT '0',
  `CarPlate` varchar(10) NOT NULL,
  `pX` float NOT NULL DEFAULT '0',
  `pY` float NOT NULL DEFAULT '0',
  `pZ` float NOT NULL DEFAULT '0',
  `pA` float DEFAULT '0',
  `Color1` int(3) NOT NULL,
  `Color2` int(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Salvarea datelor din tabel `cars`
--

INSERT INTO `cars` (`id`, `Model`, `Group`, `CarPlate`, `pX`, `pY`, `pZ`, `pA`, `Color1`, `Color2`) VALUES
(1, 411, 1, 'Null', 1536.06, -1678.25, 13.104, 0.395, 1, 0),
(2, 411, 1, 'Null', 1536.1, -1667.02, 13.103, 179.95, 1, 0),
(3, 427, 1, 'Null', 1546.55, -1653.46, 13.286, 90.339, 0, 1),
(4, 475, 1, 'Null', 1546.11, -1697.92, 13.267, 89.24, 0, 1),
(5, 596, 1, 'Null', 1554.85, -1614.94, 13.103, 161.609, 0, 1),
(6, 596, 1, 'Null', 1559.98, -1614.78, 13.103, 159.031, 0, 1),
(7, 596, 1, 'Null', 1565.25, -1614.82, 13.104, 156.782, 0, 1),
(8, 596, 1, 'Null', 1570.19, -1614.98, 13.104, 158.145, -1, -1),
(9, 596, 1, 'Null', 1575.16, -1614.92, 13.104, 154.797, -1, -1),
(10, 599, 1, 'Null', 1593.07, -1607.22, 13.581, 90.883, 0, 1),
(11, 599, 1, 'Null', 1593.23, -1615.19, 13.586, 89.872, 0, 1),
(12, 599, 1, 'Null', 1593.22, -1622.84, 13.586, 90.52, 0, 1),
(13, 523, 0, 'Null', 1566.95, -1634.17, 13.126, 1.721, 65, 65),
(14, 523, 0, 'Null', 1564.9, -1634.2, 13.123, 3.824, 43, 43),
(15, 523, 0, 'Null', 1562.89, -1633.97, 13.123, 1.182, 80, 80),
(16, 523, 0, 'Null', 1560.69, -1634.01, 13.124, 1.083, -1, -1),
(17, 523, 0, 'Null', 1558.25, -1633.99, 13.126, 3.129, -1, -1),
(18, 525, 1, 'Null', 1585.41, -1671.55, 5.774, 270.236, 0, 0),
(19, 428, 1, 'Null', 1600.31, -1683.95, 6.014, 90.43, 1, 0),
(20, 490, 2, 'Null', 636.894, -549.188, 16.383, 180.02, 205, 0),
(21, 490, 2, 'Null', 636.814, -558.436, 16.385, 180.172, 205, 0),
(22, 528, 2, 'Null', 615.555, -601.481, 17.277, 272.421, 205, 1),
(23, 411, 2, 'Null', 615.596, -591.431, 16.96, 269.276, 0, 0),
(24, 596, 2, 'Null', 621.414, -610.536, 16.892, 269.67, 205, 1),
(25, 596, 2, 'Null', 621.331, -605.846, 16.894, 271.468, 205, 1),
(26, 596, 2, 'Null', 666.069, -580.316, 16.058, 89.599, 205, 1),
(27, 596, 2, 'Null', 666.021, -586.055, 16.057, 89.62, 205, 1),
(28, 469, 3, 'Null', 1016.27, -328.91, 74.004, 268.146, 28, 28),
(29, 447, 3, 'Null', 1016.5, -341.4, 74.004, 268.013, 82, 82),
(30, 415, 3, 'Null', 1067.13, -287.884, 73.764, 178.021, 222, 222),
(31, 402, 3, 'Null', 1070.74, -288.187, 73.824, 177.894, 222, 222),
(32, 402, 3, 'Null', 1074.03, -288.182, 73.822, 180.361, 222, 222),
(33, 415, 3, 'Null', 1077.39, -287.995, 73.759, 181.003, 222, 222),
(34, 560, 3, 'Null', 1099.03, -306.534, 73.717, 90.285, 222, 222),
(35, 409, 8, 'Null', 2013.35, -1116.69, 26.003, 178.755, 233, 233),
(36, 579, 8, 'Null', 1989.02, -1118.97, 26.705, 269.647, 233, 233),
(37, 482, 8, 'Null', 1988.71, -1114.69, 26.901, 268.493, 233, 233),
(38, 405, 8, 'Null', 1988.67, -1110.62, 26.656, 270.309, 233, 233),
(39, 560, 8, 'Null', 1988.29, -1106.19, 26.486, 269.815, 233, 233),
(40, 567, 8, 'Null', 2004.35, -1105.7, 26.675, 179.133, 233, 233),
(41, 426, 8, 'Null', 1998.88, -1105.92, 26.524, 179.526, 233, 233),
(42, 461, 8, 'Null', 1987.32, -1127.8, 25.405, 177.316, 233, 233),
(43, 461, 8, 'Null', 1989.86, -1127.68, 25.355, 175.512, 233, 233),
(44, 521, 8, 'Null', 1992.58, -1127.51, 25.272, 181.95, 233, 233),
(45, 582, 5, 'Null', 736.433, -1333.95, 13.597, 179.918, 5, 1);

-- --------------------------------------------------------

--
-- Structura de tabel pentru tabelul `dealervehicles`
--

CREATE TABLE `dealervehicles` (
  `dealerID` int(3) NOT NULL,
  `dealerModel` int(4) NOT NULL,
  `dealerPrice` int(10) NOT NULL,
  `dealerPremiumPrice` int(10) NOT NULL,
  `dealerStock` int(5) NOT NULL,
  `dealerType` int(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Salvarea datelor din tabel `dealervehicles`
--

INSERT INTO `dealervehicles` (`dealerID`, `dealerModel`, `dealerPrice`, `dealerPremiumPrice`, `dealerStock`, `dealerType`) VALUES
(1, 541, 50000000, 0, 10, 1),
(2, 510, 50000, 0, 10, 1);

-- --------------------------------------------------------

--
-- Structura de tabel pentru tabelul `gps`
--

CREATE TABLE `gps` (
  `id` int(11) NOT NULL,
  `Name` varchar(30) NOT NULL,
  `gpsX` float NOT NULL,
  `gpsY` float NOT NULL,
  `gpsZ` float NOT NULL,
  `addedBy` varchar(25) NOT NULL,
  `gpsCity` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Salvarea datelor din tabel `gps`
--

INSERT INTO `gps` (`id`, `Name`, `gpsX`, `gpsY`, `gpsZ`, `addedBy`, `gpsCity`) VALUES
(1, 'Dealership', 2131.41, -1149.87, 24.215, 'L0K3D', 'Los Santos');

-- --------------------------------------------------------

--
-- Structura de tabel pentru tabelul `groups`
--

CREATE TABLE `groups` (
  `id` int(11) NOT NULL,
  `Name` varchar(50) NOT NULL,
  `leadSkin` int(3) DEFAULT '3',
  `Motto` varchar(128) NOT NULL,
  `eX` float NOT NULL,
  `eY` float NOT NULL,
  `eZ` float NOT NULL,
  `iX` float NOT NULL,
  `iY` float NOT NULL,
  `iZ` float NOT NULL,
  `SafeX` float NOT NULL,
  `SafeY` float NOT NULL,
  `SafeZ` float NOT NULL,
  `rankName1` varchar(20) NOT NULL,
  `rankName2` varchar(20) NOT NULL,
  `rankName3` varchar(20) NOT NULL,
  `rankName4` varchar(20) NOT NULL,
  `rankName5` varchar(20) NOT NULL,
  `rankName6` varchar(20) NOT NULL,
  `rankName7` varchar(20) NOT NULL,
  `Materials` int(11) NOT NULL,
  `Drugs` int(11) NOT NULL,
  `Money` int(11) NOT NULL,
  `Slots` int(3) NOT NULL,
  `Applications` int(3) NOT NULL,
  `Type` int(2) NOT NULL,
  `Interior` int(2) NOT NULL,
  `Door` int(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Salvarea datelor din tabel `groups`
--

INSERT INTO `groups` (`id`, `Name`, `leadSkin`, `Motto`, `eX`, `eY`, `eZ`, `iX`, `iY`, `iZ`, `SafeX`, `SafeY`, `SafeZ`, `rankName1`, `rankName2`, `rankName3`, `rankName4`, `rankName5`, `rankName6`, `rankName7`, `Materials`, `Drugs`, `Money`, `Slots`, `Applications`, `Type`, `Interior`, `Door`) VALUES
(1, 'Police Department', 266, 'Bun venit in factiune celor noi!', 1555.1, -1675.5, 16.195, 246.769, 63.113, 1003.64, 257.209, 69.61, 1003.64, '', '', '', '', '', '', 'Director', 0, 0, 0, 10, 1, 1, 6, 0),
(2, 'Federal Boreau of Investigation', 286, 'Bun venit in factiune celor Noi!', 627.595, -571.903, 17.635, 288.699, 167.369, 1007.17, 301.275, 187.134, 1007.17, '', '', '', '', '', 'Vice-Director', 'FBI Director', 0, 0, 0, 10, 0, 1, 3, 0),
(3, 'Hitman Agency', 186, 'Bun venit in factiune celor Noi!', 1073.29, -345.442, 73.992, -2158.75, 642.95, 1052.38, -2160.45, 639.279, 1057.59, '', '', '', '', '#5 Consigliere', '#6 Street boss', 'The Godfather', 0, 0, 0, 10, 0, 4, 1, 0),
(4, 'Taxi Cab Company', 253, 'Bun venit in factiune celor Noi!', 1753.15, -1903.17, 13.563, 0, 0, 0, -2159.23, 642.335, 1057.59, '', '', '', '', '', '', '', 0, 0, 0, 10, 0, 6, 0, 0),
(5, 'News Reporters', 188, 'Bun venit in factiune celor Noi!', 648.934, -1353.87, 13.546, 248.751, 1783.5, 701.086, 255.755, 1776.49, 701.086, '#1 Journalist', '#2 Reporter', '#3 Blogger', '#4 Commentator', '#5 Photographer', 'Vice-Director', 'Director', 0, 0, 0, 10, 1, 7, 0, 0),
(6, 'Grove Street', 271, 'Bun venit in factiune celor Noi!', 2495.45, -1691.14, 14.766, 2214.89, -1150.46, 1025.8, 2227.85, -1144.61, 1025.8, '', '', '', '', '', '', '', 23232, 0, 0, 10, 0, 3, 15, 0),
(7, 'Corleone Family', 113, 'Bun venit in factiune celor Noi!', 972.337, -1544.62, 13.604, 2214.89, -1150.46, 1025.8, 2228.25, -1144.41, 1025.8, '', '', '', '', '', '', '', 323232, 0, 0, 10, 0, 3, 15, 0),
(8, 'Ballas Family', 296, 'Bun venit in factiune celor noi! ', 2022.9, -1120.37, 26.421, 2215.15, -1150.46, 1025.8, 2227.76, -1144.73, 1025.8, '', '', '', '', '', '', '', 2323232, 0, 0, 10, 0, 3, 15, 0),
(9, 'Yakuza Family', 115, 'Bun venit in factiune celor Noi!', 693.876, -1645.81, 4.094, 2214.89, -1150.46, 1025.8, 2228.09, -1144.61, 1025.8, '', '', '', '', '', '', '', 2323232, 0, 0, 10, 0, 3, 15, 0);

-- --------------------------------------------------------

--
-- Structura de tabel pentru tabelul `jobs`
--

CREATE TABLE `jobs` (
  `id` int(11) NOT NULL,
  `Name` varchar(50) NOT NULL,
  `Type` int(2) NOT NULL,
  `Message` varchar(256) NOT NULL,
  `X` float NOT NULL,
  `Y` float NOT NULL,
  `Z` float NOT NULL,
  `Status` int(2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Salvarea datelor din tabel `jobs`
--

INSERT INTO `jobs` (`id`, `Name`, `Type`, `Message`, `X`, `Y`, `Z`, `Status`) VALUES
(1, 'Detective', 1, 'Cu acest job poti sa gasesti jucatorii online, comenzi disponibile: /creategun | /getmats', 1676.36, -1635.57, 14.227, 1),
(2, 'Arms Dealer', 2, 'Cu acest job poti sa-ti creezi arme si sa faci materiale, comenzi disponibile: /creategun | /getmats', 1833.77, -1125.63, 24.672, 1),
(3, 'Drugs Dealer', 3, '', 2164.72, -1674.93, 15.086, 1);

-- --------------------------------------------------------

--
-- Structura de tabel pentru tabelul `personalcars`
--

CREATE TABLE `personalcars` (
  `id` int(10) NOT NULL,
  `Owner` int(5) NOT NULL,
  `Model` int(4) NOT NULL,
  `PosX` float NOT NULL,
  `PosY` float NOT NULL,
  `PosZ` float NOT NULL,
  `PosA` float NOT NULL,
  `CarPlate` varchar(50) NOT NULL,
  `Color1` int(4) NOT NULL,
  `Color2` int(4) NOT NULL,
  `LockStatus` int(2) NOT NULL,
  `Age` int(4) NOT NULL,
  `Odometer` int(10) NOT NULL,
  `Insurance` int(5) NOT NULL,
  `Fuel` int(4) NOT NULL,
  `Mod1` int(5) NOT NULL,
  `Mod2` int(5) NOT NULL,
  `Mod3` int(5) NOT NULL,
  `Mod4` int(5) NOT NULL,
  `Mod5` int(5) NOT NULL,
  `Mod6` int(5) NOT NULL,
  `Mod7` int(5) NOT NULL,
  `Mod8` int(5) NOT NULL,
  `Mod9` int(5) NOT NULL,
  `Mod10` int(5) NOT NULL,
  `Mod11` int(5) NOT NULL,
  `Mod12` int(5) NOT NULL,
  `Mod13` int(5) NOT NULL,
  `Mod14` int(5) NOT NULL,
  `Mod15` int(5) NOT NULL,
  `Mod16` int(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Salvarea datelor din tabel `personalcars`
--

INSERT INTO `personalcars` (`id`, `Owner`, `Model`, `PosX`, `PosY`, `PosZ`, `PosA`, `CarPlate`, `Color1`, `Color2`, `LockStatus`, `Age`, `Odometer`, `Insurance`, `Fuel`, `Mod1`, `Mod2`, `Mod3`, `Mod4`, `Mod5`, `Mod6`, `Mod7`, `Mod8`, `Mod9`, `Mod10`, `Mod11`, `Mod12`, `Mod13`, `Mod14`, `Mod15`, `Mod16`) VALUES
(1, 1, 541, 2148.36, -1194.31, 23.559, 270.678, '', 0, 0, 1, 1547138000, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

-- --------------------------------------------------------

--
-- Structura de tabel pentru tabelul `players`
--

CREATE TABLE `players` (
  `ID` int(11) NOT NULL,
  `username` varchar(25) NOT NULL,
  `password` varchar(200) NOT NULL,
  `Email` varchar(150) DEFAULT NULL,
  `SerialCode` varchar(100) NOT NULL DEFAULT '(null)',
  `Level` int(11) NOT NULL DEFAULT '1',
  `eurekaPoints` int(6) NOT NULL,
  `AdminLevel` int(11) NOT NULL DEFAULT '0',
  `Cash` int(10) NOT NULL DEFAULT '150000',
  `Bank` int(10) NOT NULL DEFAULT '50000',
  `firstOn` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `lastOn` varchar(200) NOT NULL,
  `Sex` int(1) NOT NULL DEFAULT '0',
  `Age` int(1) NOT NULL DEFAULT '0',
  `Warns` int(11) NOT NULL,
  `Member` int(2) NOT NULL DEFAULT '0',
  `Rank` int(3) NOT NULL DEFAULT '0',
  `playerDays` int(11) NOT NULL,
  `FWarns` int(3) NOT NULL,
  `FPunish` int(3) NOT NULL,
  `Skin` int(3) NOT NULL DEFAULT '184',
  `CarLic` int(3) NOT NULL,
  `GunLic` int(3) NOT NULL,
  `BoatLic` int(3) NOT NULL,
  `FlyLic` int(3) NOT NULL,
  `Wanted` int(10) NOT NULL,
  `WantedReason` varchar(256) DEFAULT NULL,
  `jailTime` int(5) NOT NULL,
  `jailType` int(2) NOT NULL,
  `Materials` int(6) NOT NULL,
  `Drugs` int(6) NOT NULL,
  `Job` int(3) NOT NULL,
  `MatsSkill` int(2) NOT NULL DEFAULT '1',
  `MaxSlots` int(3) NOT NULL DEFAULT '1',
  `LoyalityAccount` int(2) NOT NULL,
  `LoyalityPoints` int(5) NOT NULL,
  `hudHealth` int(3) NOT NULL,
  `hudRedscreen` int(3) NOT NULL,
  `PhoneNumber` int(6) NOT NULL
) ENGINE=MyISAM DEFAULT CHARSET=latin1;

--
-- Salvarea datelor din tabel `players`
--

INSERT INTO `players` (`ID`, `username`, `password`, `Email`, `SerialCode`, `Level`, `eurekaPoints`, `AdminLevel`, `Cash`, `Bank`, `firstOn`, `lastOn`, `Sex`, `Age`, `Warns`, `Member`, `Rank`, `playerDays`, `FWarns`, `FPunish`, `Skin`, `CarLic`, `GunLic`, `BoatLic`, `FlyLic`, `Wanted`, `WantedReason`, `jailTime`, `jailType`, `Materials`, `Drugs`, `Job`, `MatsSkill`, `MaxSlots`, `LoyalityAccount`, `LoyalityPoints`, `hudHealth`, `hudRedscreen`, `PhoneNumber`) VALUES
(1, 'L0K3D', 'DCCA0C5BE60A62AE733D5F5B51FA69FEFA9C0CCFE0B3ED64AC6F850C6ECC2523FB1F86D8856B271ED7472A57D127A49004C89A96131B29DE9DC31E967A496000', 'tutorialepawno@gmail.com', '98E598D80C9440DC54DCAEEDAE8DE0CF84EEDDEE', 3, 0, 7, 869250, 50000, '2019-01-10 16:28:25', '', 1, 16, 0, 5, 1, 1547138938, 0, 0, 186, 10, 0, 0, 0, 0, 'NULL', 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0),
(2, 'Un4m3d', 'A57E011097EEBCC3E91CBCC5E09BF77D65E13E21A12A44AE3FB0BC6D63DEF78C506D536AFD0D2743580A1BCD82FAF8925E8B661B84C9EC5973082ABCEDC65C83', 'a.krizzed@gmail.com', 'C8CE0EED4C8D89F94454E4509C4FD44485DEDE49', 1, 0, 6, 145750, 50000, '2019-01-10 16:30:04', '', 1, 18, 0, 0, 0, 1547138823, 0, 0, 184, 10, 0, 0, 0, 0, 'NULL', 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0),
(3, 'Kedoo', '4049E6588263702FD2D99C677E2AA82CE72D49FE6E390B9FC8CE0EAC215A550DDA0EB5DD7E00FAC4C4509325C7DAE786F7B908912D064878EDAED85C6D432801', NULL, '49D4CC0809C5E988CC9E89EA95C4DDC990A888AE', 1, 0, 0, 150000, 50000, '2019-01-10 16:31:46', '', 0, 0, 0, 0, 0, 0, 0, 0, 184, 0, 0, 0, 0, 0, NULL, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0);

-- --------------------------------------------------------

--
-- Structura de tabel pentru tabelul `turfs`
--

CREATE TABLE `turfs` (
  `ID` int(11) NOT NULL,
  `Owner` int(3) NOT NULL,
  `MinX` float NOT NULL,
  `MinY` float NOT NULL,
  `MaxX` float NOT NULL,
  `MaxY` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Salvarea datelor din tabel `turfs`
--

INSERT INTO `turfs` (`ID`, `Owner`, `MinX`, `MinY`, `MaxX`, `MaxY`) VALUES
(1, 6, 815, -1995, 1348, -1835),
(2, 6, 815, -1835, 1036, -1481),
(3, 6, 815, -1481, 1036, -1161),
(4, 6, 1036, -1835, 1264, -1570),
(5, 6, 1036, -1570, 1264, -1312),
(6, 7, 1036, -1312, 1419, -1161),
(7, 7, 1348, -1994, 1798, -1835),
(8, 7, 1419, -1312, 1861, -1161),
(9, 7, 1861, -1313, 2362, -1161),
(10, 8, 1264, -1448, 1716, -1312),
(11, 8, 1716, -1448, 2236, -1312),
(12, 8, 1264, -1835, 1538, -1448),
(13, 8, 1538, -1604, 2045, -1448),
(14, 8, 1538, -1835, 1861, -1604),
(15, 9, 2236, -1623, 2361, -1313),
(16, 9, 2045, -1792, 2236, -1448),
(17, 9, 2236, -1838, 2361, -1623),
(18, 9, 1861, -1886, 2045, -1604);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `accounts_blocked`
--
ALTER TABLE `accounts_blocked`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `bans`
--
ALTER TABLE `bans`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `cars`
--
ALTER TABLE `cars`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `dealervehicles`
--
ALTER TABLE `dealervehicles`
  ADD PRIMARY KEY (`dealerID`);

--
-- Indexes for table `gps`
--
ALTER TABLE `gps`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `groups`
--
ALTER TABLE `groups`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `jobs`
--
ALTER TABLE `jobs`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `personalcars`
--
ALTER TABLE `personalcars`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `players`
--
ALTER TABLE `players`
  ADD PRIMARY KEY (`ID`);
ALTER TABLE `players` ADD FULLTEXT KEY `password` (`password`);

--
-- Indexes for table `turfs`
--
ALTER TABLE `turfs`
  ADD PRIMARY KEY (`ID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `accounts_blocked`
--
ALTER TABLE `accounts_blocked`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `bans`
--
ALTER TABLE `bans`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;
--
-- AUTO_INCREMENT for table `cars`
--
ALTER TABLE `cars`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=46;
--
-- AUTO_INCREMENT for table `dealervehicles`
--
ALTER TABLE `dealervehicles`
  MODIFY `dealerID` int(3) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;
--
-- AUTO_INCREMENT for table `gps`
--
ALTER TABLE `gps`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `groups`
--
ALTER TABLE `groups`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=10;
--
-- AUTO_INCREMENT for table `jobs`
--
ALTER TABLE `jobs`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT for table `personalcars`
--
ALTER TABLE `personalcars`
  MODIFY `id` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
--
-- AUTO_INCREMENT for table `players`
--
ALTER TABLE `players`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;
--
-- AUTO_INCREMENT for table `turfs`
--
ALTER TABLE `turfs`
  MODIFY `ID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
