---------------------------------------------------------
------------------PARALLEL PROGRAMMING-------------------
-------------------COURSE WORK PART 2--------------------
----       --ADA. SEMAPHORES. PROTECTED UNITS--     -----
----              MA = MB*MC + MO*ME*a              -----
---------------------------------------------------------
-------------     MAIN MODULE PRG2     ------------------
---------------------------------------------------------
-----------------CREATED ON 20.03.2016-------------------
----------------BY OLEG PEDORENKO, IP-31-----------------
---------------------------------------------------------

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Synchronous_Task_Control; use Ada.Synchronous_Task_Control;
with Ada.Float_Text_IO;   use Ada.Float_Text_IO;
with Ada.Real_Time;      use Ada.Real_Time;
with Ada.Command_Line; use Ada.Command_Line;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Data;

procedure p03 is

  N: Integer := 8;
  P: Integer := 2;
  H: Integer := 4;

  
begin
  --Read N and P from command line
  if(Argument_Count > 0) then 
    N := Integer'Value(Argument(1));
  end if;  
  if(Argument_Count > 1) then 
    P := Integer'Value(Argument(2));
  end if;  
  H := N/P;
  
  declare  
    -- Types
    package Data_S is new Data(N, 100); use Data_S;
    subtype Range_H is Integer range 1..H;
    subtype Range_P is Integer range 1..P;
    subtype Range_2P is Integer range 2..P;
    
    -- Calculate MAh
    procedure Calculate
      (MBa, MCha, MOa, MEha: in Proto_Matrix; 
      aa: in Scalar; 
      MAha: out Proto_Matrix) is
      Sum1, Sum2: Scalar;
    begin
      for I in MBa'Range loop
        for J in MCha'Range loop
          Sum1 := 0.0;
          Sum2 := 0.0;
          for K in MBa'Range loop
            Sum1 := Sum1 + (MBa(I)(K) * MCha(K)(J)); --MB * MCh
            Sum2 := Sum2 + (MOa(I)(K) * MEha(K)(J)); -- MO * MEh
            null;
          end loop;
          MAha(I)(J) := Sum1 + Sum2 * aa; -- Sum1 + Sum2 * aa;
        end loop;
      end loop;
    end;
    
    -- Task type for T1 (Task that enters data)
    task type T1 is
      pragma Storage_Size(100000000);
    end T1;
    
    task type TX(I: Integer) is
      pragma Storage_Size(100000000);
      entry Data(d_MB, d_MCh, d_MO, d_MEh: in Proto_Matrix; d_a: in Scalar);
      entry Result(r_MAh: out Proto_Matrix);
    end TX;

    T1_T: access T1;
    TX_Arr: array(Range_2P) of access TX;
    
    task body T1 is
      B, E: Integer;
      MA, MB, MC, MO, ME: Matrix;
      a: Scalar;
    begin
      Put_Line("Task T1 started");
      --Initialize MA
      Fill(MA);
      --Enter MB, MC, MO, ME, a
      Put_Line("MB =   "); Input(MB); 
      Put_Line("MC =   "); Input(MC); 
      Put_Line("MO =   "); Input(MO); 
      Put_Line("ME =   "); Input(ME);      
      Put_Line("a =    "); Input(a); Put(a); Put_Line("");      
      -- Надсилання даних по задачах;
      for I in Range_2P loop
        B := (H*(I-1) + 1);
        E := (H*I);
        if (I = P) then
          E := N;
        end if;       
        TX_Arr(I).Data(MB, MC(B..E), MO, ME(B..E), a);
      end loop;
      -- Обчислення даних;
      Calculate(MB, MC(Range_H), MO, ME(Range_H), a, MA(Range_H));
      -- Прийом даних;
      for I in Range_2P loop
        B := (H*(I-1) + 1);
        E := (H*I);
        if (I = P) then
          E := N;
        end if;       
        TX_Arr(I).Result(MA(B..E));
      end loop;      
      -- Виведення результату;
      Put_Line("MA =   "); Output(MA);
      Put_Line("Task T1 finished");
    end T1;
    
    task body TX is
      l_MB,  l_MO: Matrix;
      l_MCh, l_MEh: Proto_Matrix(Range_H);
      l_MAh: Proto_Matrix(Range_H);
      l_a: Scalar;
    begin
      Put_Line("Task T" & Integer'Image(I) &" started");
      -- Прийом даних з Т1
      accept Data(d_MB, d_MCh, d_MO, d_MEh: in Proto_Matrix; d_a: in Scalar) do
        l_MB := d_MB;
        l_MCh := d_MCh;
        l_MO := d_MO;
        l_MEh := d_MEh;
        l_a := d_a;
      end Data;
      -- Обчислення МАн
      Calculate(l_MB, l_MO, l_MCh, l_MEh, l_a, l_MAh);
      -- Передати МАн у Т1
      accept Result(r_MAh: out Proto_Matrix) do
        r_MAh := l_MAh;
      end Result;
      Put_Line("Task T" & Integer'Image(I) &" finished");    
    end TX;
  
  begin
    --Initialize MA
    Fill(MA);
    --Enter MB, MC, MO, ME, a
    Put_Line("MB =   "); Input(MB); 
    Put_Line("MC =   "); Input(MC); 
    Put_Line("MO =   "); Input(MO); 
    Put_Line("ME =   "); Input(ME);      
    Put_Line("a =    "); Input(a); Put(a); Put_Line("");    
    
    for I in Range_2P loop
      B := (H*(I-1) + 1);
      E := (H*I);
      if (I = P) then
        E := N;
      end if;
      Calculate(MB, MC, MO, ME, a, MA);
    end loop;
    
    Put_Line("MA =   "); Output(MA);
  end;
  
end p03;