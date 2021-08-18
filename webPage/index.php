<?php
include 'SampRconAPI.php';
if(isset($_POST['apeleaza'])) {
	$rcon = new SampRconAPI('127.0.0.1', 7777, 'pass'); // parametri: ip, port, rcon password
	$rcon->Call('rconFunct');
}
?>

<!DOCTYPE html>
<html>
	<head>
		<title>Page Title</title>
	</head>
	<body>
		<center>
		<h1>Server Query and RCON API</h1>
		<form action="" method="post">
			  <button type="submit" name="apeleaza">Apeleaza functia</button>
		</form>
		</center>
	</body>
</html>