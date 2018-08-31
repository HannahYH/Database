{\rtf1\ansi\ansicpg936\cocoartf1348\cocoasubrtf170
{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;}
\paperw11900\paperh16840\margl1440\margr1440\vieww18140\viewh14880\viewkind0
\pard\tx560\tx1120\tx1680\tx2240\tx2800\tx3360\tx3920\tx4480\tx5040\tx5600\tx6160\tx6720\pardirnatural

\f0\fs22 \cf0 \CocoaLigature0 -- COMP9311 18s1 Project 1\
\
--\
-- MyMyUNSW Solution Template\
\
\
-- Q1:\
-- find students who has got at least 85 marks in more than 20 courses\
create or replace view CourseMarkCount(student, courseCount)\
as\
select student, count(course)\
from course_enrolments\
where mark>=85\
group by student;\
\
-- find international students\
create or replace view StudentIntl(uid, id, name)\
as\
select p.unswid,p.id,p.name\
from People p, Students s\
where s.stype='intl' and p.id=s.id;\
\
create or replace view Q1(unswid, name)\
as\
select s.uid,s.name\
from StudentIntl s, CourseMarkCount c\
where c.courseCount>20 and s.id=c.student;\
\
\
--... SQL statements, possibly using other views/functions defined by you ...\
\
\
\
\
-- Q2:\
--\
create or replace view Q2(unswid, name)\
as\
select unswid,longname\
from rooms\
where capacity>=20\
and building=(select id from buildings where name='Computer Science Building')\
and rtype=(select id from room_types where description='Meeting Room');\
\
--... SQL statements, possibly using other views/functions defined by you ...\
\
\
\
-- Q3:\
create or replace view Q3(unswid, name)\
as\
select unswid,name\
from people\
where id in(select staff from course_staff where course\
        in(select course from course_enrolments\
        where student=(select id from people where given='Stefan' and family='Bilek')));\
--... SQL statements, possibly using other views/functions defined by you ...\
\
\
\
\
-- Q4:\
create or replace view subject3331(courseid)\
as\
select c.id\
from courses c,subjects s\
where s.code='COMP3331' and c.subject=s.id;\
\
create or replace view StudentSubject3331(sid)\
as\
select stu.id\
from course_enrolments ce,subject3331 s3331,students stu\
where s3331.courseid=ce.course and ce.student=stu.id;\
\
create or replace view subject3231(courseid)\
as\
select c.id\
from courses c,subjects s\
where s.code='COMP3231' and c.subject=s.id;\
\
create or replace view StudentSubject3231(sid)\
as\
select stu.id\
from course_enrolments ce,subject3231 s3231,students stu\
where s3231.courseid=ce.course and ce.student=stu.id;\
\
create or replace view Q4(unswid, name)\
as\
select p.unswid,p.name\
from people p\
where p.id in((select sid from StudentSubject3331) except (select sid from StudentSubject3231));\
\
--... SQL statements, possibly using other views/functions defined by you ...\
\
\
\
\
-- Q5:\
create or replace view localStu(sid)\
as\
select s.id\
from students s\
where s.stype='local';\
\
create or replace view S1_11(semesterid)\
as\
select id\
from semesters\
where year=2011 and term='S1';\
\
\
create or replace view chemistry(streamid)\
as\
select str.id\
from Streams str\
where str.name='Chemistry';\
\
create or replace view chemistry11S1(c1_id)\
as\
select pe.student\
from S1_11 sem,Stream_enrolments se,Program_enrolments pe,chemistry chem\
where se.stream=chem.streamid\
        and se.partof=pe.id\
        and pe.semester=sem.semesterid;\
\
create or replace view chemistry11S1Local(c1l_id)\
as\
select distinct ls.sid\
from localStu ls,chemistry11S1 chem11s1\
where chem11s1.c1_id=ls.sid;\
\
create or replace view Q5a(num)\
as\
select count(c1l_id)\
from chemistry11S1Local;\
--... SQL statements, possibly using other views/functions defined by you ...\
\
\
-- Q5:\
create or replace view intlStu(sid)\
as\
select s.id\
from students s\
where s.stype='intl';\
\
create or replace view CSE11S1(cse11_id)\
as\
select pe.student\
from S1_11 sem,OrgUnits org,Programs pro,Program_enrolments pe\
where org.longname='School of Computer Science and Engineering'\
        and pro.offeredBy=org.id\
        and pe.program=pro.id\
        and pe.semester=sem.semesterid;\
\
create or replace view CSEStu(cse11intl_id)\
as\
select distinct intl.sid\
from intlStu intl,CSE11S1 cse\
where intl.sid=cse.cse11_id;\
\
create or replace view Q5b(num)\
as\
select count(cse11intl_id)\
from CSEStu;\
--... SQL statements, possibly using other views/functions defined by you ...\
\
\
\
-- Q6:\
create or replace function\
        Q6(inputcode text) returns text\
as\
$$\
        select code||' '||name||' '||uoc from Subjects where code=inputcode;\
--... SQL statements, possibly using other views/functions defined by you ...\
$$ language sql;\
\
\
-- Q7:\
create or replace view programIntl(id, intl_count)\
as\
select pe.program,count(s.id)\
from students s,Program_enrolments pe\
where s.stype='intl'\
        and s.id=pe.student\
        and pe.program in(select id from programs)\
group by pe.program;\
\
create or replace view programAll(id, all_count)\
as\
select pe.program,count(s.id)\
from students s,Program_enrolments pe\
where s.id=pe.student\
        and pe.program in(select id from programs)\
group by pe.program;\
\
create or replace view programPercent(proid, percent)\
as\
select proIntl.id,100*proIntl.intl_count/proAll.all_count\
from programIntl proIntl,programAll proAll\
where proIntl.id=proAll.id;\
\
create or replace view Q7(code, name)\
as\
select pro.code,pro.name\
from programs pro,programPercent propercent\
where pro.id=propercent.proid and propercent.percent>50;\
\
--... SQL statements, possibly using other views/functions defined by you ...\
\
\
\
\
-- Q8:\
create or replace view course_mark_count(courseid, markcount, markavg)\
as\
select ce.course,count(ce.mark),avg(ce.mark)\
from courses c,Course_enrolments ce\
where ce.course=c.id\
group by ce.course;\
\
create or replace view highest_mark(maxmark)\
as\
select max(markavg)\
from course_mark_count\
where markcount>=15;\
\
create or replace view highest_avg_course(subid, semid)\
as\
select c.subject,c.semester\
from course_mark_count cmc,highest_mark hm,courses c\
where cmc.markavg=hm.maxmark\
        and c.id=cmc.courseid;\
\
create or replace view Q8(code, name, semester)\
as\
select s.code,s.name,sem.name\
from subjects s,highest_avg_course hac,Semesters sem\
where sem.id=hac.semid and hac.subid=s.id;\
\
--... SQL statements, possibly using other views/functions defined by you ...\
\
\
-- Q9:\
create or replace view school_org_id(id)\
as\
select id\
from OrgUnit_types\
where name='School';\
\
create or replace view target_orgunit(staffid, orgid, startdate)\
as\
select aff.staff,aff.orgUnit,aff.starting\
from Affiliations aff,school_org_id soi\
where aff.orgUnit in(select id from OrgUnits where utype=soi.id)\
        and aff.role=(select id from Staff_roles where name='Head of School')\
        and aff.isPrimary='t'\
        and aff.ending is null;\
\
create or replace view staff_info(staffid, subjects)\
as\
select distinct cs.staff,s.code\
from target_orgunit torg,Course_staff cs,Courses c,subjects s\
where cs.staff=torg.staffid and c.id=cs.course and c.subject=s.id;\
\
create or replace view staff_subnum(staffid, num_subjects)\
as\
select staffid,count(subjects)\
from staff_info\
group by staffid;\
\
create or replace view Q9(name, school, email, starting, num_subjects)\
as\
select p.name,org.longname,p.email,torg.startdate,si.num_subjects\
from people p,OrgUnits org,staff_subnum si,target_orgunit torg\
where p.id=torg.staffid and org.id=torg.orgid and si.staffid=torg.staffid\
order by si.staffid;\
\
--... SQL statements, possibly using other views/functions defined by you ...\
\
-- Q10:\
create or replace view subject_comp93(subid, subcode, subname)\
as\
select s.id,s.code,s.name\
from subjects s\
where s.code like 'COMP93%';\
\
create or replace view semester_S1_S2_period(semid,semterm,semyear)\
as\
select sem.term||sem.year,sem.term,sem.year\
from semesters sem\
where (sem.term='S1' or sem.term='S2')\
        and sem.starting>='2003-01-01' and sem.ending<='2012-12-31'\
order by sem.year,sem.term;\
\
create or replace view target_temp(subid,semterm,semyear,semid)\
as\
select distinct sc.subid,sp.semterm,sp.semyear,sp.semid\
from subject_comp93 sc,semester_S1_S2_period sp,courses c,Course_enrolments ce\
where sc.subid=c.subject and sp.semid=(select term||year from semesters where id=c.semester) and c.id=ce.course;\
\
create or replace view target_sub_count(subid,count)\
as\
select subid,count(semid)\
from target_temp\
group by subid;\
\
create or replace view HD_marks_S1(subid, semid, count)\
as\
select distinct c.subject,sp.semid,count(ce.mark)\
from target_sub_count sc,semester_S1_S2_period sp,courses c,Course_enrolments ce\
where sc.count=20 and sc.subid=c.subject and sp.semid=(select term||year from semesters where id=c.semester)\
        and c.id=ce.course and ce.mark>=85 and sp.semterm='S1'\
group by c.id,sp.semid;\
\
create or replace view HD_marks_S2(subid, semid, count)\
as\
select distinct c.subject,sp.semid,count(ce.mark)\
from target_sub_count sc,semester_S1_S2_period sp,courses c,Course_enrolments ce\
where sc.count=20 and sc.subid=c.subject and sp.semid=(select term||year from semesters where id=c.semester)\
        and c.id=ce.course and ce.mark>=85 and sp.semterm='S2'\
group by c.id,sp.semid;\
\
create or replace view all_marks_S1(subid, semid, count)\
as\
select distinct c.subject,sp.semid,count(ce.mark)\
from target_sub_count sc,semester_S1_S2_period sp,courses c,Course_enrolments ce\
where sc.count=20 and sc.subid=c.subject and sp.semid=(select term||year from semesters where id=c.semester)\
        and c.id=ce.course and ce.mark>=0 and sp.semterm='S1'\
group by c.id,sp.semid;\
\
create or replace view all_marks_S2(subid, semid, count)\
as\
select distinct c.subject,sp.semid,count(ce.mark)\
from target_sub_count sc,semester_S1_S2_period sp,courses c,Course_enrolments ce\
where sc.count=20 and sc.subid=c.subject and sp.semid=(select term||year from semesters where id=c.semester)\
        and c.id=ce.course and ce.mark>=0 and sp.semterm='S2'\
group by c.id,sp.semid;\
\
create or replace view HD_rate_S1_t(subid, semid, rate)\
as\
select All_m.subid,All_m.semid,(case when (HD.count*0.1)/(All_m.count*0.1) is null then 0.0 else (HD.count*0.1)/(All_m.count*0.1) end)\
from all_marks_S1 All_m left join HD_marks_S1 HD\
on HD.subid=All_m.subid and HD.semid=All_m.semid\
order by All_m.subid,All_m.semid;\
\
create or replace view HD_rate_S2_t(subid, semid, rate)\
as\
select All_m.subid,All_m.semid,(case when (HD.count*0.1)/(All_m.count*0.1) is null then 0.0 else (HD.count*0.1)/(All_m.count*0.1) end)\
from all_marks_S2 All_m left join HD_marks_S2 HD\
on HD.subid=All_m.subid and HD.semid=All_m.semid\
order by All_m.subid,All_m.semid;\
\
create or replace view HD_rate_S1(subid, semyear, rate)\
as\
select distinct hd.subid,sp.semyear,hd.rate\
from semester_S1_S2_period sp,HD_rate_S1_t hd\
where sp.semid=hd.semid;\
\
create or replace view HD_rate_S2(subid, semyear, rate)\
as\
select distinct hd.subid,sp.semyear,hd.rate\
from semester_S1_S2_period sp,HD_rate_S2_t hd\
where sp.semid=hd.semid;\
\
create or replace view Q10(code, name, year, s1_HD_rate, s2_HD_rate)\
as\
select sc.subcode,sc.subname,substring(cast(s1.semyear as char(4)), 3, 4),cast(s1.rate as numeric(4,2)),cast(s2.rate as numeric(4,2))\
from HD_rate_S1 s1,HD_rate_S2 s2,subject_comp93 sc\
where s1.subid=s2.subid and s1.semyear=s2.semyear and sc.subid=s1.subid\
order by s1.subid;\
\
--... SQL statements, possibly using other views/functions defined by you ...\
                                                   }