from flask import Flask,request,render_template,redirect,url_for,flash,session,send_file
from flask_session import Session
from otp import genotp
from cmail import send_mail
from stoken import entoken,detoken
from io import BytesIO
import flask_excel as excel
import mysql.connector
import re
app=Flask(__name__)
app.config['SESSION_TYPE']='filesystem'
app.secret_key='codegnan2025'
Session(app)
excel.init_excel(app)
mydb=mysql.connector.connect(user='root',host='localhost',password='admin',db='snmp')
@app.route('/')
def home():
    session['user']=None
    return render_template("index.html")



@app.route('/register',methods=['GET','POST'])
def register():
     if request.method=='POST':
        print(request.form)
        username=request.form['username']
        password=request.form['password']
        email=request.form['email']
        cursor=mydb.cursor()
        cursor.execute('select count(email) from users where email=%s',[email])
        emailcount=cursor.fetchone()
        print(type(emailcount))
        if emailcount[0]==0:
            otp=genotp()
            userdata={'user_name':username,'user_password':password,'user_email':email,'otp':otp}
            subject=f'verifiaction mail for SNM Project'
            body=f'OTP for SNM Register verify:  {otp}'
            send_mail(to=email,subject=subject,body=body)
            flash('The OTP has been sent to given Email')
            return redirect(url_for('otpverify',user_data=entoken(data=userdata)))
        elif emailcount[0]==1:
            flash('Email already existsted')
        else:
            return f'something went wrong'

     return render_template('register.html')



@app.route('/otpverify/<user_data>',methods=['GET','POST'])
def otpverify(user_data):
    if session.get('user'):
        if request.method=='POST':
            userotp=request.form['userotp']
            duser_data=detoken(data=user_data)
            if duser_data['otp']==userotp:
                cursor=mydb.cursor()
                cursor.execute('insert into users(username,password,email)values(%s,%s,%s)',[duser_data['user_name'],duser_data['user_password'],duser_data['user_email']])
                mydb.commit()
                cursor.close()
                flash('Details Registered Successfully.')
                return redirect(url_for('login'))
            else:
                flash('Invalid otp')
        return render_template('otp.html')
    else:
        flash('Please login')
        return redirect(url_for('login'))


@app.route('/login',methods=['GET','POST'])
def login():
    if not session.get('user'):
        if request.method=='POST':
            email=request.form['email']
            password=request.form['password']
            cursor=mydb.cursor(buffered=True)
            cursor.execute('select count(email) from users where email=%s',[email])
            count_email=cursor.fetchone()
            if count_email[0]==1:
                cursor.execute('select password from users where email=%s',[email])
                stored_password=cursor.fetchone()
                if stored_password[0]==password:
                    session['user']=email
                    print(session)
                    return redirect(url_for('dashboard'))
                else:
                    flash('password wrong')
                    return redirect(url_for('login'))
            elif count_email[0]==0:
                flash('Email not found')
                return redirect(url_for('login'))


        return render_template("login.html")
    else:
        return redirect(url_for('dashboard'))

@app.route('/dashboard',methods=['GET','POST'])
def dashboard():
    if session.get('user'):
        return render_template('dashboard.html')

    else:
        flash('Please login')
        return redirect(url_for('login'))

@app.route('/addnotes',methods=['GET','POST'])
def addnotes():
    if session.get('user'):
        if request.method=='POST':
            title=request.form['title']
            description=request.form['description']
            cursor=mydb.cursor(buffered=True)
            cursor.execute('insert into notes(title,description,added_by) values(%s,%s,%s)',[title,description,session.get('user')])
            mydb.commit()
            cursor.close()
            flash(f'notes{title} added successfully')
            return redirect(url_for('viewallnotes')) 
        return render_template('addnotes.html')
    else:
        flash('Please login')
        return redirect(url_for('login'))
@app.route('/viewallnotes')
def viewallnotes():
    if session.get('user'):
        cursor=mydb.cursor()
        cursor.execute('select nid,title,created_at from notes where added_by=%s',[session.get('user')])
        allnotesdata=cursor.fetchall()
        cursor.close()
        return render_template('viewallnotes.html',allnotesdata=allnotesdata)
    else:
        flash('Please login')
        return redirect(url_for('login'))


@app.route('/viewnotes/<nid>')
def viewnotes(nid):
    if session.get('user'):
        cursor=mydb.cursor()
        cursor.execute('select * from notes where nid=%s and added_by=%s',[nid,session.get('user')])
        notesdata=cursor.fetchone()
        cursor.close()
        return render_template('viewnotes.html',notesdata=notesdata)
    else:
        flash('Please login')
        return redirect(url_for('login'))

@app.route('/updatenotes/<nid>',methods=['GET','POST'])
def updatenotes(nid):
    if session.get('user'):
        cursor=mydb.cursor(buffered=True)
        cursor.execute('select * from notes where nid=%s and added_by=%s',[nid,session.get('user')])
        notesdata=cursor.fetchone()
        print(notesdata)
        if request.method=='POST':
            u_title=request.form['title']
            u_description=request.form['description']
            cursor=mydb.cursor(buffered=True)
            cursor.execute('update notes set title=%s,description=%s where nid=%s and added_by=%s',[u_title,u_description,nid,session.get('user')])
            mydb.commit()
            flash(f'notes{u_title} update sucessfully')
            return redirect(url_for('viewnotes',nid=nid))
        return render_template('updatenotes.html',notesdata=notesdata)
    else:
        flash('Please login')
        return redirect(url_for('login'))

@app.route('/deletenotes/<nid>', methods=['GET', 'POST'])
def deletenotes(nid):
    if session.get('user'):
        cursor = mydb.cursor()
        cursor.execute('DELETE FROM notes WHERE nid=%s AND added_by=%s', [nid, session.get('user')])
        mydb.commit()
        cursor.close()
        flash(f'Note ID {nid} deleted successfully.')
        return redirect(url_for('viewallnotes'))
    else:
        flash('Please login')
        return redirect(url_for('login'))

@app.route('/fileupload',methods=['GET','POST'])
def fileupload():
    if session.get('user'):
        if request.method=='POST':
            file_data=request.files['file']
            f_name=file_data.filename
            fdata=file_data.read()
            cursor=mydb.cursor(buffered=True)
            cursor.execute('insert into filedata(filename,fdata,added_by) values(%s,%s,%s)',[f_name,fdata,session.get('user')])
            mydb.commit()
            cursor.close()
            flash(f'{f_name} added successfully')
            return redirect(url_for('viewallfiles'))
            
        return render_template('fileupload.html')
    else:
        flash('Please login')
        return redirect(url_for('login'))

@app.route('/viewallfiles')
def viewallfiles():
    if session.get('user'):
        cursor=mydb.cursor()
        cursor.execute('select fid,filename,created_at from filedata where added_by=%s',[session.get('user')])
        allfiledata=cursor.fetchall()
        cursor.close()
        return render_template('viewallfiles.html',allfiledata=allfiledata)
    else:
        flash('Please login')
        return redirect(url_for('login'))


@app.route('/viewfile/<fid>')
def viewfile(fid):
    if session.get('user'):
        cursor=mydb.cursor(buffered=True)
        cursor.execute('select fdata,filename from filedata where fid=%s and added_by=%s',[fid,session.get('user')])
        filedata=cursor.fetchone()
        f_data=BytesIO(filedata[0])
        return send_file(f_data,as_attachment=False,download_name=filedata[1])
    else:
        flash('Please login')
        return redirect(url_for('login'))

@app.route('/downloadfile/<fid>')
def downloadfile(fid):
    if session.get('user'):
        cursor=mydb.cursor(buffered=True)
        cursor.execute('select fdata,filename from filedata where fid=%s and added_by=%s',[fid,session.get('user')])
        filedata=cursor.fetchone()
        f_data=BytesIO(filedata[0])
        return send_file(f_data,as_attachment=True,download_name=filedata[1])
    else:
        flash('Please login')
        return redirect(url_for('login'))





@app.route('/deletefile/<int:fid>')
def deletefile(fid):
    if session.get('user'):
        cursor = mydb.cursor()
        cursor.execute("SELECT filename FROM filedata WHERE fid=%s AND added_by=%s", (fid, session.get('user')))
        result = cursor.fetchone()
        if result:
            cursor.execute("DELETE FROM filedata WHERE fid=%s AND added_by=%s", (fid, session.get('user')))
            mydb.commit()
            flash(f"File '{result[0]}' deleted successfully", "success")
        else:
            flash("File not found or you do not have permission to delete it.", "danger")
        cursor.close()
        return redirect(url_for('viewallfiles'))
    else:
        flash('Please login')
        return redirect(url_for('login'))

@app.route('/getexceldata')
def getexceldata():
    if session.get('user'):
        cursor=mydb.cursor(buffered=True)
        cursor.execute('select * from notes where added_by=%s',[session.get('user')])
        content=cursor.fetchall()
        columns=['notes_id','title','notes_data','created_at']
        data=[list(i) for i in content]
        data.insert(0,columns)
        return excel.make_response_from_array(data,'xlsx',filename='notesdata')
    else:
        flash('Please login')
        return redirect(url_for('login'))



@app.route('/search',methods=['GET','POST'])
def search():
    if session.get('user'):
        if request.method=='POST':
            search_data=request.form['s_data']
            strng=['A-Za-z0-9']
            pattern=re.compile(f'^{strng}',re.IGNORECASE)
            if (pattern.match(search_data)):
                cursor=mydb.cursor(buffered=True)
                cursor.execute('select nid, title, created_at from notes where nid like %s or title like %s or description like %s and added_by=%s',[search_data+'%',search_data+'%',search_data+'%',session.get('user')])
                matcheddata=cursor.fetchall()
                return render_template('dashboard.html',sdata=matcheddata)
            else:
                flash('No Data Found')
        return render_template('dashboard.html')
    else:
        flash('Please login')
        return redirect(url_for('login'))



@app.route('/forgotpassword',methods=('GET','POST'))
def forgotpassword():
    if session.get('user'):
        if request.method=='POST':
            f_email=request.form['email']
            cursor=mydb.cursor(buffered=True)
            cursor.execute('select count(*) from users where email=%s',[f_email])
            count_email=cursor.fetchone()
            if count_email[0]==1:
                subject=f'Reset link for SNM website forgot password'
                body=f"click to reset link: {url_for('newpassword',data=entoken(f_email),_external=True)}"
                send_mail(to=f_email,subject=subject,body=body)
                flash(f'Reset link has been set to given mailID{f_email}')
                return redirect(url_for('login'))
            elif count_email[0]==0:
                flash(f'Please register your account')
                return redirect(url_for('register'))
                
        return render_template('forgot.html')
    else:
        flash('Please login')
        return redirect(url_for('login'))

@app.route('/newpassword/<data>',methods=['GET','POST'])
def newpassword(data):
    if session.get('user'):
        if request.method=='POST':
            npassword=request.form['new_password']
            cpassword=request.form['confirm_password']
            if npassword==cpassword:
                email=detoken(data)
                cursor=mydb.cursor(buffered=True)
                cursor.execute('update users set password=%s where email=%s',[npassword,email])
                mydb.commit()
                return(f'newpassword updated successfully Please login')
                # return redirect(url_for('login'))
            else:
                flash('Mismatched password Please check')
                return redirect(url_for('newpassword',data=data))
        return render_template('newpassword.html')
    else:
        flash('Please login')
        return redirect(url_for('login'))






        













@app.route('/logout')
def logout():
    if session.get('user'):
        session.pop('user')
        return redirect(url_for('home'))
    return redirect(url_for('home'))
app.run(use_reloader=True,debug=True)