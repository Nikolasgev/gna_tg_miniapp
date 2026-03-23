import React, { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { X, Mail, Phone, MessageSquare, Briefcase, MessageCircle } from 'lucide-react'
import emailjs from '@emailjs/browser'

const ContactModal = ({ isOpen, onClose, selectedService = null }) => {
  const [formData, setFormData] = useState({
    contactMethod: '',
    contactValue: '',
    businessType: '',
  })
  const [submitted, setSubmitted] = useState(false)
  const [isSubmitting, setIsSubmitting] = useState(false)

  useEffect(() => {
    const key = import.meta.env.VITE_EMAILJS_PUBLIC_KEY
    if (key) {
      emailjs.init(key)
    }
  }, [])

  const handleSubmit = async (e) => {
    e.preventDefault()
    setIsSubmitting(true)

    try {
      // Формируем сообщение для отправки
      const serviceInfo = selectedService
        ? `\n\nВыбранная услуга:\nТип: ${selectedService.type === 'subscription' ? 'Подписка' : 'Разовая услуга'}\nНазвание: ${selectedService.name}\nЦена: ${selectedService.price} ${selectedService.period}\nОписание: ${selectedService.description}`
        : ''

      const message = `Новая заявка с сайта

Контактные данные:
Способ связи: ${formData.contactMethod === 'whatsapp' ? 'WhatsApp' : formData.contactMethod === 'telegram' ? 'Telegram' : formData.contactMethod === 'phone' ? 'Звонок' : 'Email'}
Контакт: ${formData.contactValue}
Вид деятельности: ${formData.businessType}${serviceInfo}`

      // Отправляем через EmailJS
      // ВАЖНО: Нужно настроить EmailJS на https://www.emailjs.com/
      // 1. Создайте аккаунт
      // 2. Создайте email service (Gmail, Outlook и т.д.)
      // 3. Создайте email template
      // 4. Получите Service ID, Template ID и Public Key
      
      // Временное решение: отправка через mailto (работает без настройки)
      const mailtoLink = `mailto:nikolasgev1@gmail.com?subject=Новая заявка с сайта&body=${encodeURIComponent(message)}`
      window.location.href = mailtoLink

      // Альтернатива: использовать EmailJS (раскомментируйте после настройки)
      /*
      await emailjs.send(
        import.meta.env.VITE_EMAILJS_SERVICE_ID || '',
        import.meta.env.VITE_EMAILJS_TEMPLATE_ID || '',
        {
          to_email: 'nikolasgev1@gmail.com',
          message: message,
          contact_method: formData.contactMethod,
          contact_value: formData.contactValue,
          business_type: formData.businessType,
          service_name: selectedService?.name || 'Не выбрано',
          service_type: selectedService?.type || 'Не выбрано',
          service_price: selectedService?.price || 'Не выбрано',
        },
        import.meta.env.VITE_EMAILJS_PUBLIC_KEY || ''
      )
      */

      setSubmitted(true)
      setTimeout(() => {
        setSubmitted(false)
        setFormData({ contactMethod: '', contactValue: '', businessType: '' })
        onClose()
      }, 2000)
    } catch (error) {
      console.error('Ошибка отправки формы:', error)
      alert('Произошла ошибка при отправке формы. Пожалуйста, попробуйте еще раз.')
    } finally {
      setIsSubmitting(false)
    }
  }

  const formatPhoneNumber = (value) => {
    // Удаляем все нецифровые символы
    let digits = value.replace(/\D/g, '')
    
    // Если начинается с 7 или 8, заменяем на +7
    if (digits.startsWith('7') || digits.startsWith('8')) {
      digits = '7' + digits.slice(1)
    }
    
    // Если не начинается с 7, добавляем 7 в начало
    if (!digits.startsWith('7')) {
      digits = '7' + digits
    }
    
    // Ограничиваем до 11 цифр (7 + 10)
    digits = digits.slice(0, 11)
    
    // Форматируем: +7 (XXX) XXX-XX-XX
    if (digits.length <= 1) {
      return '+7'
    } else if (digits.length <= 4) {
      return `+7 (${digits.slice(1)}`
    } else if (digits.length <= 7) {
      return `+7 (${digits.slice(1, 4)}) ${digits.slice(4)}`
    } else if (digits.length <= 9) {
      return `+7 (${digits.slice(1, 4)}) ${digits.slice(4, 7)}-${digits.slice(7)}`
    } else {
      return `+7 (${digits.slice(1, 4)}) ${digits.slice(4, 7)}-${digits.slice(7, 9)}-${digits.slice(9)}`
    }
  }

  const handleChange = (e) => {
    const { name, value } = e.target
    
    if (name === 'contactValue') {
      // Для телефона форматируем номер
      const isPhoneField = formData.contactMethod === 'phone' || formData.contactMethod === 'whatsapp'
      
      if (isPhoneField) {
        const formatted = formatPhoneNumber(value)
        setFormData({
          ...formData,
          contactValue: formatted,
        })
      } else {
        // Для других полей просто сохраняем значение
        setFormData({
          ...formData,
          contactValue: value,
        })
      }
    } else {
      setFormData({
        ...formData,
        [name]: value,
        // Сбрасываем значение контакта при смене способа связи
        ...(name === 'contactMethod' && { contactValue: '' }),
      })
    }
  }

  const handlePhoneKeyDown = (e) => {
    // Разрешаем: Backspace, Delete, Tab, Escape, Enter, стрелки
    if ([8, 9, 27, 13, 46, 35, 36, 37, 38, 39, 40].indexOf(e.keyCode) !== -1 ||
      // Разрешаем: Ctrl+A, Ctrl+C, Ctrl+V, Ctrl+X
      (e.keyCode === 65 && e.ctrlKey === true) ||
      (e.keyCode === 67 && e.ctrlKey === true) ||
      (e.keyCode === 86 && e.ctrlKey === true) ||
      (e.keyCode === 88 && e.ctrlKey === true) ||
      // Разрешаем: Home, End
      (e.keyCode >= 35 && e.keyCode <= 40)) {
      return
    }
    // Запрещаем все остальное, если это не цифра
    if ((e.shiftKey || (e.keyCode < 48 || e.keyCode > 57)) && (e.keyCode < 96 || e.keyCode > 105)) {
      e.preventDefault()
    }
  }

  const contactMethods = [
    { value: 'whatsapp', label: 'WhatsApp', icon: MessageCircle, placeholder: '+7 (999) 123-45-67' },
    { value: 'telegram', label: 'Telegram', icon: MessageSquare, placeholder: '@username' },
    { value: 'phone', label: 'Звонок', icon: Phone, placeholder: '+7 (999) 123-45-67' },
    { value: 'email', label: 'Email', icon: Mail, placeholder: 'your@email.com' },
  ]

  const getContactInputType = () => {
    if (formData.contactMethod === 'email') return 'email'
    if (formData.contactMethod === 'telegram') return 'text'
    return 'tel'
  }

  const getContactLabel = () => {
    const method = contactMethods.find(m => m.value === formData.contactMethod)
    return method ? method.label : 'Контакт'
  }

  const getContactPlaceholder = () => {
    const method = contactMethods.find(m => m.value === formData.contactMethod)
    return method ? method.placeholder : ''
  }

  const getContactIcon = () => {
    const method = contactMethods.find(m => m.value === formData.contactMethod)
    return method ? method.icon : MessageSquare
  }

  const ContactIcon = getContactIcon()

  if (!isOpen) return null

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        {/* Backdrop */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
          className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        />

        {/* Modal */}
        <motion.div
          initial={{ opacity: 0, scale: 0.95, y: 20 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={{ opacity: 0, scale: 0.95, y: 20 }}
          className="relative bg-white rounded-2xl shadow-2xl max-w-md w-full max-h-[90vh] overflow-y-auto"
        >
          {/* Close Button */}
          <button
            onClick={onClose}
            className="absolute top-4 right-4 p-2 hover:bg-gray-100 rounded-full transition-colors z-10"
          >
            <X className="w-5 h-5 text-gray-600" />
          </button>

          {/* Content */}
          <div className="p-8">
            <div className="text-center mb-8">
              <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-slate-700 to-slate-900 rounded-full mb-4">
                <MessageSquare className="w-8 h-8 text-white" />
              </div>
              <h2 className="text-2xl font-bold text-gray-900 mb-2">
                Оставить заявку
              </h2>
              <p className="text-gray-600">
                Заполните форму, и мы свяжемся с вами в ближайшее время
              </p>
              {selectedService && (
                <div className="mt-4 p-3 bg-slate-50 rounded-lg border border-slate-200">
                  <p className="text-sm text-gray-600 mb-1">
                    <span className="font-semibold">Выбранная услуга:</span>
                  </p>
                  <p className="text-sm font-semibold text-slate-700">
                    {selectedService.name} - {selectedService.price} {selectedService.period}
                  </p>
                  <p className="text-xs text-gray-500 mt-1">
                    {selectedService.type === 'subscription' ? 'Подписка' : 'Разовая услуга'}
                  </p>
                </div>
              )}
            </div>

            {submitted ? (
              <motion.div
                initial={{ opacity: 0, scale: 0.9 }}
                animate={{ opacity: 1, scale: 1 }}
                className="text-center py-8"
              >
                <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <svg
                    className="w-8 h-8 text-green-600"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M5 13l4 4L19 7"
                    />
                  </svg>
                </div>
                <h3 className="text-xl font-bold text-gray-900 mb-2">
                  Спасибо!
                </h3>
                <p className="text-gray-600">
                  Мы свяжемся с вами в ближайшее время
                </p>
              </motion.div>
            ) : (
              <form onSubmit={handleSubmit} className="space-y-6">
                {/* Contact Method Selection */}
                <div>
                  <label className="block text-sm font-semibold text-gray-700 mb-3">
                    Как лучше связаться?
                  </label>
                  <div className="grid grid-cols-2 gap-3">
                    {contactMethods.map((method) => {
                      const Icon = method.icon
                      const isSelected = formData.contactMethod === method.value
                      return (
                        <button
                          key={method.value}
                          type="button"
                          onClick={() => {
                            setFormData({
                              ...formData,
                              contactMethod: method.value,
                              contactValue: '',
                            })
                          }}
                          className={`p-4 rounded-xl border-2 transition-all ${
                            isSelected
                              ? 'border-slate-700 bg-slate-50 shadow-md'
                              : 'border-gray-200 hover:border-gray-300 bg-white'
                          }`}
                        >
                          <Icon
                            className={`w-6 h-6 mx-auto mb-2 ${
                              isSelected ? 'text-slate-700' : 'text-gray-400'
                            }`}
                          />
                          <span
                            className={`text-sm font-medium block ${
                              isSelected ? 'text-slate-700' : 'text-gray-600'
                            }`}
                          >
                            {method.label}
                          </span>
                        </button>
                      )
                    })}
                  </div>
                </div>

                {/* Contact Value Field (appears after method selection) */}
                {formData.contactMethod && (
                  <motion.div
                    initial={{ opacity: 0, height: 0 }}
                    animate={{ opacity: 1, height: 'auto' }}
                    exit={{ opacity: 0, height: 0 }}
                    transition={{ duration: 0.3 }}
                  >
                    <label
                      htmlFor="contactValue"
                      className="block text-sm font-semibold text-gray-700 mb-2"
                    >
                      <ContactIcon className="w-4 h-4 inline mr-2" />
                      {getContactLabel()}
                    </label>
                    <input
                      type={getContactInputType()}
                      id="contactValue"
                      name="contactValue"
                      value={formData.contactValue}
                      onChange={handleChange}
                      onFocus={(e) => {
                        // Если поле пустое и это телефон, устанавливаем +7
                        if ((formData.contactMethod === 'phone' || formData.contactMethod === 'whatsapp') && !formData.contactValue) {
                          setFormData({
                            ...formData,
                            contactValue: '+7',
                          })
                          // Устанавливаем курсор после +7
                          setTimeout(() => {
                            e.target.setSelectionRange(4, 4) // После "+7 ("
                          }, 0)
                        }
                      }}
                      onKeyDown={(e) => {
                        if (formData.contactMethod === 'phone' || formData.contactMethod === 'whatsapp') {
                          handlePhoneKeyDown(e)
                          // Если пользователь пытается удалить +7, предотвращаем это
                          if (e.key === 'Backspace' && formData.contactValue === '+7') {
                            e.preventDefault()
                          }
                        }
                      }}
                      required
                      className="w-full px-4 py-3 bg-white border border-gray-300 rounded-lg focus:ring-2 focus:ring-slate-500 focus:border-transparent transition-all"
                      placeholder={getContactPlaceholder()}
                    />
                  </motion.div>
                )}

                {/* Business Type */}
                <div>
                  <label
                    htmlFor="businessType"
                    className="block text-sm font-semibold text-gray-700 mb-2"
                  >
                    <Briefcase className="w-4 h-4 inline mr-2" />
                    Вид деятельности
                  </label>
                  <select
                    id="businessType"
                    name="businessType"
                    value={formData.businessType}
                    onChange={handleChange}
                    required
                    className="w-full pl-4 pr-10 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-slate-500 focus:border-transparent transition-all bg-white appearance-none bg-[url('data:image/svg+xml;charset=UTF-8,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2212%22%20height%3D%2212%22%20viewBox%3D%220%200%2012%2012%22%3E%3Cpath%20fill%3D%22%23334155%22%20d%3D%22M6%209L1%204h10z%22%2F%3E%3C%2Fsvg%3E')] bg-[length:12px_12px] bg-[right_16px_center] bg-no-repeat"
                  >
                    <option value="">Выберите вид деятельности</option>
                    <option value="cafe">Кафе / Ресторан</option>
                    <option value="shop">Интернет-магазин</option>
                    <option value="retail">Розничная торговля</option>
                    <option value="food">Доставка еды</option>
                    <option value="services">Услуги</option>
                    <option value="other">Другое</option>
                  </select>
                </div>

                {/* Submit Button */}
                <button
                  type="submit"
                  disabled={!formData.contactMethod || !formData.contactValue || !formData.businessType || isSubmitting}
                  className="w-full bg-gradient-to-r from-slate-700 to-slate-900 text-white py-3 px-6 rounded-lg font-semibold hover:shadow-lg transition-all hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100"
                >
                  {isSubmitting ? 'Отправка...' : 'Отправить заявку'}
                </button>

                <p className="text-xs text-gray-500 text-center">
                  Нажимая кнопку, вы соглашаетесь с{' '}
                  <a href="#" className="text-slate-700 hover:underline">
                    политикой конфиденциальности
                  </a>
                </p>
              </form>
            )}
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  )
}

export default ContactModal

