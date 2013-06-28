using System;
using System.Windows;
using System.Windows.Data;
using System.Globalization;

using LiveReload.Model;

namespace LiveReload
{
    [ValueConversion(typeof(Project), typeof(Visibility))]
    public class SelectedProjectConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture) {
            return (value == null) ? Visibility.Hidden : Visibility.Visible;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) {
            throw new NotImplementedException();
        }
    }
}
