using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;

namespace LSToolkit
{
    public partial class Form2 : Form
    {
        //18 hr
        //*60 = 1080 game time
        //game shows 18:00

        //800
        // / 60 = 13.3333333 real time
        //game shows 13:20


        public int sg = 1;

        public Form2()
        {
            InitializeComponent();
        }

        private void button1_Click(object sender, EventArgs e)
        {
            Form1 parent = (Form1)this.Owner;
            parent.returntextbox(sg, 0).Text = numericUpDown1.Value.ToString();
            this.Hide();
        }

        void numericUpDown1_MouseWheel(object sender, System.Windows.Forms.MouseEventArgs e)
        {
            TimeSpan timespan = TimeSpan.FromHours(Convert.ToDouble(numericUpDown1.Value / 60));
            dateTimePicker1.Value = new DateTime(2000, 1, 1, timespan.Hours, timespan.Minutes, timespan.Seconds);
        }

        private void numericUpDown1_MouseDown(object sender, MouseEventArgs e)
        {
            TimeSpan timespan = TimeSpan.FromHours(Convert.ToDouble(numericUpDown1.Value / 60));
            dateTimePicker1.Value = new DateTime(2000,1,1,timespan.Hours,timespan.Minutes,timespan.Seconds);
        }

        private void numericUpDown1_KeyDown(object sender, KeyEventArgs e)
        {
            TimeSpan timespan = TimeSpan.FromHours(Convert.ToDouble(numericUpDown1.Value / 60));
            dateTimePicker1.Value = new DateTime(2000, 1, 1, timespan.Hours, timespan.Minutes, timespan.Seconds);
        }

        private void dateTimePicker1_ValueChanged(object sender, EventArgs e)
        {
            decimal dec = Convert.ToDecimal(TimeSpan.Parse(dateTimePicker1.Value.Hour + ":" + dateTimePicker1.Value.Minute).TotalHours);
            numericUpDown1.Value = dec * 60;
        }
    }
}
