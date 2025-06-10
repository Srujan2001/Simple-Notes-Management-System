-- MySQL dump 10.13  Distrib 8.0.41, for Win64 (x86_64)
--
-- Host: localhost    Database: snmp
-- ------------------------------------------------------
-- Server version	8.0.41

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `filedata`
--

DROP TABLE IF EXISTS `filedata`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `filedata` (
  `fid` int unsigned NOT NULL AUTO_INCREMENT,
  `filename` varchar(20) NOT NULL,
  `fdata` longblob,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `added_by` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`fid`),
  UNIQUE KEY `filename` (`filename`),
  KEY `added_by` (`added_by`),
  CONSTRAINT `filedata_ibfk_1` FOREIGN KEY (`added_by`) REFERENCES `users` (`email`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `filedata`
--

LOCK TABLES `filedata` WRITE;
/*!40000 ALTER TABLE `filedata` DISABLE KEYS */;
INSERT INTO `filedata` VALUES (23,'simple (1).txt',_binary 'hello world','2025-06-05 14:17:35','srujanravuri2001@gmail.com'),(25,'app.py',_binary 'from flask import Flask,request,render_template,redirect,url_for,flash,session,send_file\r\nfrom flask_session import Session\r\nfrom otp import genotp\r\nfrom cmail import send_mail\r\nfrom stoken import entoken,detoken\r\nfrom io import BytesIO\r\nimport mysql.connector\r\napp=Flask(__name__)\r\napp.config[\'SESSION_TYPE\']=\'filesystem\'\r\napp.secret_key=\'codegnan2025\'\r\nSession(app)\r\nmydb=mysql.connector.connect(user=\'root\',host=\'localhost\',password=\'admin\',db=\'snmp\')\r\n@app.route(\'/\')\r\ndef home():\r\n    return render_template(\"index.html\")\r\n\r\n@app.route(\'/register\',methods=[\'GET\',\'POST\'])\r\ndef register():\r\n     if request.method==\'POST\':\r\n        print(request.form)\r\n        username=request.form[\'username\']\r\n        password=request.form[\'password\']\r\n        email=request.form[\'email\']\r\n        cursor=mydb.cursor()\r\n        cursor.execute(\'select count(email) from users where email=%s\',[email])\r\n        emailcount=cursor.fetchone()\r\n        print(type(emailcount))\r\n        if emailcount[0]==0:\r\n            otp=genotp()\r\n            userdata={\'user_name\':username,\'user_password\':password,\'user_email\':email,\'otp\':otp}\r\n            subject=f\'verifiaction mail for SNM Project\'\r\n            body=f\'OTP for SNM Register verify:  {otp}\'\r\n            send_mail(to=email,subject=subject,body=body)\r\n            flash(\'The OTP has been sent to given Email\')\r\n            return redirect(url_for(\'otpverify\',user_data=entoken(data=userdata)))\r\n        elif emailcount[0]==1:\r\n            flash(\'Email already existsted\')\r\n        else:\r\n            return f\'something went wrong\'\r\n\r\n     return render_template(\'register.html\')\r\n\r\n\r\n\r\n@app.route(\'/otpverify/<user_data>\',methods=[\'GET\',\'POST\'])\r\ndef otpverify(user_data):\r\n    if request.method==\'POST\':\r\n        userotp=request.form[\'userotp\']\r\n        duser_data=detoken(data=user_data)\r\n        if duser_data[\'otp\']==userotp:\r\n            cursor=mydb.cursor()\r\n            cursor.execute(\'insert into users(username,password,email)values(%s,%s,%s)\',[duser_data[\'user_name\'],duser_data[\'user_password\'],duser_data[\'user_email\']])\r\n            mydb.commit()\r\n            cursor.close()\r\n            flash(\'Details Registered Successfully.\')\r\n            return redirect(url_for(\'login\'))\r\n        else:\r\n            flash(\'Invalid otp\')\r\n    return render_template(\'otp.html\')\r\n\r\n@app.route(\'/login\',methods=[\'GET\',\'POST\'])\r\ndef login():\r\n    if request.method==\'POST\':\r\n        email=request.form[\'email\']\r\n        password=request.form[\'password\']\r\n        cursor=mydb.cursor(buffered=True)\r\n        cursor.execute(\'select count(email) from users where email=%s\',[email])\r\n        count_email=cursor.fetchone()\r\n        if count_email[0]==1:\r\n            cursor.execute(\'select password from users where email=%s\',[email])\r\n            stored_password=cursor.fetchone()\r\n            if stored_password[0]==password:\r\n                session[\'user\']=email\r\n                print(session)\r\n                return redirect(url_for(\'dashboard\'))\r\n            else:\r\n                flash(\'password wrong\')\r\n                return redirect(url_for(\'login\'))\r\n        elif count_email[0]==0:\r\n            flash(\'Email not found\')\r\n            return redirect(url_for(\'login\'))\r\n\r\n\r\n    return render_template(\"login.html\")\r\n\r\n@app.route(\'/dashboard\',methods=[\'GET\',\'POST\'])\r\ndef dashboard():\r\n    return render_template(\'dashboard.html\')\r\n\r\n@app.route(\'/addnotes\',methods=[\'GET\',\'POST\'])\r\ndef addnotes():\r\n    if request.method==\'POST\':\r\n        title=request.form[\'title\']\r\n        description=request.form[\'description\']\r\n        cursor=mydb.cursor(buffered=True)\r\n        cursor.execute(\'select count(nid) from notes\')\r\n        nid_count=cursor.fetchone()\r\n        if nid_count:\r\n            nid=nid_count[0]+1\r\n            cursor.execute(\'insert into notes(nid,title,description,added_by) values(%s,%s,%s,%s)\',[nid,title,description,session.get(\'user\')])\r\n            mydb.commit()\r\n            cursor.close()\r\n            flash(f\'notes{title} added successfully\')\r\n            return redirect(url_for(\'viewallnotes\'))\r\n        else:\r\n            flash(\'nid not found\')\r\n            return redirect(url_for(\'dashboard\'))\r\n        \r\n    return render_template(\'addnotes.html\')\r\n@app.route(\'/viewallnotes\')\r\ndef viewallnotes():\r\n    cursor=mydb.cursor()\r\n    cursor.execute(\'select nid,title,created_at from notes where added_by=%s\',[session.get(\'user\')])\r\n    allnotesdata=cursor.fetchall()\r\n    cursor.close()\r\n    return render_template(\'viewallnotes.html\',allnotesdata=allnotesdata)\r\n\r\n@app.route(\'/viewnotes/<nid>\')\r\ndef viewnotes(nid):\r\n    cursor=mydb.cursor()\r\n    cursor.execute(\'select * from notes where nid=%s and added_by=%s\',[nid,session.get(\'user\')])\r\n    notesdata=cursor.fetchone()\r\n    cursor.close()\r\n    return render_template(\'viewnotes.html\',notesdata=notesdata)\r\n\r\n@app.route(\'/updatenotes/<nid>\',methods=[\'GET\',\'POST\'])\r\ndef updatenotes(nid):\r\n    cursor=mydb.cursor(buffered=True)\r\n    cursor.execute(\'select * from notes where nid=%s and added_by=%s\',[nid,session.get(\'user\')])\r\n    notesdata=cursor.fetchone()\r\n    print(notesdata)\r\n    if request.method==\'POST\':\r\n        u_title=request.form[\'title\']\r\n        u_description=request.form[\'description\']\r\n        cursor=mydb.cursor(buffered=True)\r\n        cursor.execute(\'update notes set title=%s,description=%s where nid=%s and added_by=%s\',[u_title,u_description,nid,session.get(\'user\')])\r\n        mydb.commit()\r\n        flash(f\'notes{u_title} update sucessfully\')\r\n        return redirect(url_for(\'viewnotes\',nid=nid))\r\n    return render_template(\'updatenotes.html\',notesdata=notesdata)\r\n\r\n@app.route(\'/deletenotes/<nid>\', methods=[\'GET\', \'POST\'])\r\ndef deletenotes(nid):\r\n    cursor = mydb.cursor()\r\n    cursor.execute(\'DELETE FROM notes WHERE nid=%s AND added_by=%s\', [nid, session.get(\'user\')])\r\n    mydb.commit()\r\n    cursor.close()\r\n    flash(f\'Note ID {nid} deleted successfully.\')\r\n    return redirect(url_for(\'viewallnotes\'))\r\n\r\n@app.route(\'/fileupload\',methods=[\'GET\',\'POST\'])\r\ndef fileupload():\r\n    if request.method==\'POST\':\r\n        file_data=request.files[\'file\']\r\n        f_name=file_data.filename\r\n        fdata=file_data.read()\r\n        cursor=mydb.cursor(buffered=True)\r\n        cursor.execute(\'insert into filedata(filename,fdata,added_by) values(%s,%s,%s)\',[f_name,fdata,session.get(\'user\')])\r\n        mydb.commit()\r\n        cursor.close()\r\n        flash(f\'{f_name} added successfully\')\r\n        return redirect(url_for(\'viewallfiles\'))\r\n        \r\n    return render_template(\'fileupload.html\')\r\n\r\n@app.route(\'/viewallfiles\')\r\ndef viewallfiles():\r\n    cursor=mydb.cursor()\r\n    cursor.execute(\'select fid,filename,created_at from filedata where added_by=%s\',[session.get(\'user\')])\r\n    allfiledata=cursor.fetchall()\r\n    cursor.close()\r\n    return render_template(\'viewallfiles.html\',allfiledata=allfiledata)\r\n\r\n\r\n@app.route(\'/viewfile/<fid>\')\r\ndef viewfile(fid):\r\n    cursor=mydb.cursor(buffered=True)\r\n    cursor.execute(\'select fdata,filename from filedata where fid=%s and added_by=%s\',[fid,session.get(\'user\')])\r\n    filedata=cursor.fetchone()\r\n    f_data=BytesIO(filedata[0])\r\n    return send_file(f_data,as_attachment=False,download_name=filedata[1])\r\n\r\n@app.route(\'/downloadfile/<fid>\')\r\ndef downloadfile(fid):\r\n    cursor=mydb.cursor(buffered=True)\r\n    cursor.execute(\'select fdata,filename from filedata where fid=%s and added_by=%s\',[fid,session.get(\'user\')])\r\n    filedata=cursor.fetchone()\r\n    f_data=BytesIO(filedata[0])\r\n    return send_file(f_data,as_attachment=True,download_name=filedata[1])\r\n\r\n\r\n\r\n\r\n\r\n@app.route(\'/deletefile/<int:fid>\')\r\ndef deletefile(fid):\r\n    cursor = mydb.cursor()\r\n    cursor.execute(\"SELECT filename FROM filedata WHERE fid=%s AND added_by=%s\", (fid, session.get(\'user\')))\r\n    result = cursor.fetchone()\r\n    if result:\r\n        cursor.execute(\"DELETE FROM filedata WHERE fid=%s AND added_by=%s\", (fid, session.get(\'user\')))\r\n        mydb.commit()\r\n        flash(f\"File \'{result[0]}\' deleted successfully\", \"success\")\r\n    else:\r\n        flash(\"File not found or you do not have permission to delete it.\", \"danger\")\r\n    cursor.close()\r\n    return redirect(url_for(\'viewallfiles\'))\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n@app.route(\'/logout\')\r\ndef logout():\r\n     return redirect(url_for(\'home\'))\r\napp.run(use_reloader=True,debug=True)','2025-06-05 14:28:32','srujanravuri2001@gmail.com');
/*!40000 ALTER TABLE `filedata` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notes`
--

DROP TABLE IF EXISTS `notes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notes` (
  `nid` int NOT NULL AUTO_INCREMENT,
  `title` varchar(225) DEFAULT NULL,
  `description` longtext,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `added_by` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`nid`),
  KEY `added_by` (`added_by`),
  CONSTRAINT `notes_ibfk_1` FOREIGN KEY (`added_by`) REFERENCES `users` (`email`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notes`
--

LOCK TABLES `notes` WRITE;
/*!40000 ALTER TABLE `notes` DISABLE KEYS */;
INSERT INTO `notes` VALUES (2,'MYSQL','MySQL is a widely used, open-source relational database management system (RDBMS) that utilizes Structured Query Language (SQL) to store, manage, and retrieve data.','2025-06-02 14:46:58','srujanravuri2001@gmail.com'),(12,'python','programming language\r\n','2025-06-08 20:22:17','srujanravuri2001@gmail.com');
/*!40000 ALTER TABLE `notes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `username` varchar(50) NOT NULL,
  `email` varchar(50) NOT NULL,
  `password` varchar(50) NOT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES ('srujan','srujanravuri2001@gmail.com','srujan');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-06-10 13:56:13
