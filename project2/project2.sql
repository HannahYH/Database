{\rtf1\ansi\ansicpg936\cocoartf1348\cocoasubrtf170
{\fonttbl\f0\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;}
\paperw11900\paperh16840\margl1440\margr1440\vieww26360\viewh8260\viewkind0
\pard\tx560\tx1120\tx1680\tx2240\tx2800\tx3360\tx3920\tx4480\tx5040\tx5600\tx6160\tx6720\pardirnatural

\f0\fs22 \cf0 \CocoaLigature0 --Q1:\
\
drop type if exists RoomRecord cascade;\
create type RoomRecord as (valid_room_number integer, bigger_room_number integer);\
\
create or replace function Q1(course_id integer)\
    returns RoomRecord\
as $$\
declare num_stu integer; num_stu_wait integer; result_q1 RoomRecord;\
begin\
        select count(student) into num_stu\
        from Course_enrolments\
        where course=course_id;\
\
        select count(student) into num_stu_wait\
        from Course_enrolment_waitlist\
        where course=course_id;\
\
        if num_stu=0 and num_stu_wait=0 then\
                raise exception 'INVALID COURSEID';\
        else\
                select count(id) into result_q1.valid_room_number\
                from Rooms\
                where capacity>=num_stu;\
                select count(id) into result_q1.bigger_room_number\
                from Rooms\
                where capacity>=(num_stu+num_stu_wait);\
                return result_q1;\
        end if;\
end;\
--... SQL statements, possibly using other views/functions defined by you ...\
$$ language plpgsql;\
\
\
--Q2:\
\
drop type if exists TeachingRecord cascade;\
create type TeachingRecord as (cid integer, term char(4), code char(8), name text, uoc integer, average_mark integer, highest_mark integer, median_mark integer, totalEnrols integer);\
\
\
CREATE or replace FUNCTION _final_median(anyarray) RETURNS float8 AS $$\
  WITH q AS\
  (\
     SELECT val\
     FROM unnest($1) val\
     WHERE VAL IS NOT NULL\
     ORDER BY 1\
  ),\
  cnt AS\
  (\
    SELECT COUNT(*) AS c FROM q\
  )\
  SELECT AVG(val)::float8\
  FROM\
  (\
    SELECT val FROM q\
    LIMIT  2 - MOD((SELECT c FROM cnt), 2)\
    OFFSET GREATEST(CEIL((SELECT c FROM cnt) / 2.0) - 1,0)\
  ) q2;\
$$ LANGUAGE SQL IMMUTABLE;\
\
drop AGGREGATE if exists median(anyelement);\
CREATE AGGREGATE median(anyelement) (\
  SFUNC=array_append,\
  STYPE=anyarray,\
  FINALFUNC=_final_median,\
  INITCOND='\{\}'\
);\
\
drop type if exists CourseInfo cascade;\
create type CourseInfo as (term char(4), code char(8), name text, uoc integer, average_mark integer, highest_mark integer, median_mark integer, totalEnrols integer);\
\
create or replace function Q2_course_info(course_id integer)\
        returns CourseInfo\
as $$\
declare result_course CourseInfo;\
begin\
        select sub.uoc, sub.name, sub.code into result_course.uoc, result_course.name, result_course.code\
        from courses cou, subjects sub\
        where cou.id=course_id and sub.id=cou.subject;\
\
        select substring(cast(sem.year as char(4)), 3, 4)||lower(sem.term) into result_course.term\
        from semesters sem, courses cou\
        where cou.id=course_id and sem.id=cou.semester;\
\
        select round(avg(mark)),max(mark),median(mark) into result_course.average_mark,result_course.highest_mark,result_course.median_mark\
        from Course_enrolments\
        where course=course_id and mark is not null;\
\
        select count(student) into result_course.totalEnrols\
        from Course_enrolments\
        where course=course_id and mark is not null;\
\
        return result_course;\
end;\
--... SQL statements, possibly using other views/functions defined by you ...\
$$ language plpgsql;\
\
\
create or replace function Q2(staff_id integer)\
        returns setof TeachingRecord\
as $$\
declare count_row integer; item integer; result_row TeachingRecord%rowtype; course_record CourseInfo;\
begin\
        select count(*) into count_row from staff where id=staff_id;\
        if count_row=0 then\
                raise exception 'INVALID STAFFID';\
        else\
                for item in select course from Course_staff where staff=staff_id\
                loop\
                select * into course_record from q2_course_info(item);\
                if course_record.totalEnrols > 0 then\
                        result_row.cid := item;\
                        result_row.term := course_record.term;\
                        result_row.code := course_record.code;\
                        result_row.name := course_record.name;\
                        result_row.uoc := course_record.uoc;\
                        result_row.average_mark := course_record.average_mark;\
                        result_row.highest_mark := course_record.highest_mark;\
                        result_row.median_mark := course_record.median_mark;\
                        result_row.totalEnrols := course_record.totalEnrols;\
                        return next result_row;\
                end if;\
                end loop;\
                return;\
        end if;\
end;\
--... SQL statements, possibly using other views/functions defined by you ...\
$$ language plpgsql;\
\
--Q3:\
drop type if exists StuCourseCount cascade;\
create type StuCourseCount as (id integer, count integer);\
\
create or replace function Q3_find_students_count(org_id integer, num_courses integer)\
  returns setof StuCourseCount\
as $$\
declare stu_course_count StuCourseCount%rowtype;\
begin\
        for stu_course_count in select ce.student,count(ce.student)\
        from Course_enrolments ce,Courses c,OrgUnit_groups org_g,subjects s\
        where (org_g.owner=52 or org_g.member=52) and s.offeredby=org_g.member and c.subject=s.id and c.id=ce.course group by ce.student\
        loop\
                if stu_course_count.count > num_courses then\
                        return next stu_course_count;\
                end if;\
        end loop;\
        return;\
end;\
--... SQL statements, possibly using other views/functions defined by you ...\
$$ language plpgsql;\
\
create or replace function Q3_find_students_mark(org_id integer, min_score integer)\
  returns setof StuCourseCount\
as $$\
declare stu_course_count StuCourseCount%rowtype;\
begin\
        for stu_course_count in select ce.student,max(ce.mark)\
        from Course_enrolments ce,Courses c,OrgUnit_groups org_g,subjects s\
        where (org_g.owner=52 or org_g.member=52) and s.offeredby=org_g.member and c.subject=s.id and c.id=ce.course group by ce.student\
        loop\
                if stu_course_count.count >= min_score then\
                        return next stu_course_count;\
                end if;\
        end loop;\
        return;\
end;\
--... SQL statements, possibly using other views/functions defined by you ...\
$$ language plpgsql;\
\
drop type if exists CourseInfoQ3 cascade;\
create type CourseInfoQ3 as (sid integer, cid integer, code char(8), name text, semester text,org_name text,score integer);\
\
create or replace function Q3_course_info(stu_id integer)\
  returns setof CourseInfoQ3\
as $$\
declare row_num integer := 0;s_id integer;course_id integer;row_mark integer;stu_course_info CourseInfoQ3%rowtype;\
begin\
        for s_id,course_id,row_mark in\
        select distinct sid,cid,mark from find_all_stu_course_info where sid=stu_id order by mark desc,cid asc\
        loop\
                if row_num<5 then\
                        select sid,cid,code,sname,sem_name,org_name,mark into stu_course_info from find_all_stu_course_info where mark=row_mark and sid=s_id and cid=course_id;\
                        return next stu_course_info;\
                else\
                        return;\
                end if;\
                row_num := row_num + 1;\
        end loop;\
        return;\
end;\
--... SQL statements, possibly using other views/functions defined by you ...\
$$ language plpgsql;\
\
drop type if exists CourseRecord cascade;\
create type CourseRecord as (unswid integer, student_name text, course_records text);\
\
create or replace function Q3(org_id integer, num_courses integer, min_score integer)\
  returns setof CourseRecord\
as $$\
declare text_mark text; count_row integer; stu_id integer; row_course_info CourseRecord%rowtype; stu_course_info CourseInfoQ3%rowtype;\
begin\
        select count(*) into count_row from OrgUnits where id=org_id;\
        if count_row=0 then\
                raise exception 'INVALID ORGID';\
        else\
        execute\
        '\
        create or replace view find_all_stu_course_info(sid,cid,code,sname,sem_name,org_name,mark)\
        as\
        with recursive find_all_member(id) as (select member from orgunit_groups where owner='||org_id||'\
        union all\
        select og.member from find_all_member fa, orgunit_groups og where og.owner=fa.id)\
\
        select ce.student,ce.course,s.code,s.name,sem.name,org.name,case when ce.mark is null then 0 else ce.mark end\
        from subjects s,semesters sem,course_enrolments ce,courses c,orgunits org,find_all_member fa\
        where ce.course=c.id and c.subject=s.id and sem.id=c.semester and org.id=fa.id and\
        s.offeredby=fa.id and ce.mark is not null order by ce.mark desc;\
        ';\
\
        for stu_id in select c.id\
        from q3_find_students_mark($1,$3) mark,q3_find_students_count($1,$2) c\
        where mark.id=c.id\
        loop\
                select unswid,name into row_course_info.unswid,row_course_info.student_name\
                from people where id=stu_id;\
                row_course_info.course_records := '';\
                for stu_course_info in select * from Q3_course_info(stu_id)\
                loop\
                        text_mark := cast(stu_course_info.score as text);\
                        if text_mark = '0' then\
                                text_mark := 'null';\
                        end if;\
                        row_course_info.course_records := row_course_info.course_records||stu_course_info.code||', '||\
                                                        stu_course_info.name||', '||\
                                                        stu_course_info.semester||', '||stu_course_info.org_name||', '||\
                                                        text_mark||chr(10);\
                end loop;\
                return next row_course_info;\
        end loop;\
        end if;\
end;\
--... SQL statements, possibly using other views/functions defined by you ...\
$$ language plpgsql;}