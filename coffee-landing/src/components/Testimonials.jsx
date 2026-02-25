import React from 'react'
import { motion } from 'framer-motion'
import { Coffee, Smartphone, CreditCard, Truck, Settings, DollarSign, Check, User, HeadphonesIcon, Sparkles } from 'lucide-react'

const Testimonials = () => {
  const benefits = [
    {
      icon: Coffee,
      title: 'Быстрый запуск',
      description: 'Настройте кофейню за день. Добавьте меню, подключите оплату и начните принимать заказы.',
    },
    {
      icon: Smartphone,
      title: 'В Telegram',
      description: 'Клиенты заказывают прямо в мессенджере. Не нужно устанавливать отдельное приложение.',
    },
    {
      icon: CreditCard,
      title: 'Онлайн-оплата',
      description: 'Принимайте платежи картами через YooKassa. Безопасно и удобно для клиентов.',
    },
    {
      icon: Truck,
      title: 'Доставка',
      description: 'Автоматический расчет стоимости через Яндекс.Доставка или настройте свою доставку.',
    },
    {
      icon: Settings,
      title: 'Простое управление',
      description: 'Удобная админ-панель. Обновляйте меню, цены и отслеживайте заказы в реальном времени.',
    },
    {
      icon: DollarSign,
      title: 'Экономия',
      description: 'Не нужно нанимать разработчиков. Готовая платформа с полным функционалом.',
    },
  ]

  return (
    <section id="testimonials" className="py-20 bg-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <h2 className="text-4xl md:text-5xl font-bold text-gray-900 mb-4">
            Почему выбирают <span className="text-gradient">нас</span>
          </h2>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Преимущества платформы для вашей кофейни
          </p>
        </motion.div>

        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
          {benefits.map((benefit, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, y: 30 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.6, delay: index * 0.1 }}
              className="bg-gradient-to-br from-coffee-50 to-white rounded-2xl p-6 border border-coffee-100 hover:shadow-xl transition-all"
            >
              <div className="w-12 h-12 bg-gradient-to-br from-coffee-700 via-coffee-800 to-amber-900 rounded-xl flex items-center justify-center mb-4">
                <benefit.icon className="w-6 h-6 text-white" />
              </div>
              <h3 className="text-xl font-bold text-gray-900 mb-2">
                {benefit.title}
              </h3>
              <p className="text-gray-600 leading-relaxed">
                {benefit.description}
              </p>
            </motion.div>
          ))}
        </div>

        {/* Early Access CTA */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.6, delay: 0.6 }}
          className="mt-16"
        >
          <div className="bg-white rounded-3xl shadow-2xl overflow-hidden border border-coffee-100">
            <div className="bg-gradient-to-r from-coffee-700 via-coffee-800 to-amber-900 px-8 py-6">
              <h3 className="text-3xl font-bold text-white mb-2 text-center">Станьте одной из первых кофеен</h3>
              <p className="text-coffee-100 text-center max-w-2xl mx-auto">
                Присоединяйтесь к ранним пользователям и получите эксклюзивные преимущества
              </p>
            </div>
            <div className="p-8">
              <div className="grid md:grid-cols-3 gap-6">
                <div className="text-center">
                  <div className="w-16 h-16 bg-gradient-to-br from-coffee-100 to-coffee-50 rounded-2xl flex items-center justify-center mx-auto mb-4">
                    <User className="w-8 h-8 text-coffee-700" />
                  </div>
                  <h4 className="font-bold text-gray-900 mb-2">Персональный менеджер</h4>
                  <p className="text-sm text-gray-600">Выделенный специалист для решения ваших задач</p>
                </div>
                <div className="text-center">
                  <div className="w-16 h-16 bg-gradient-to-br from-coffee-100 to-coffee-50 rounded-2xl flex items-center justify-center mx-auto mb-4">
                    <HeadphonesIcon className="w-8 h-8 text-coffee-700" />
                  </div>
                  <h4 className="font-bold text-gray-900 mb-2">Приоритетная поддержка</h4>
                  <p className="text-sm text-gray-600">Быстрое решение вопросов в первую очередь</p>
                </div>
                <div className="text-center">
                  <div className="w-16 h-16 bg-gradient-to-br from-coffee-100 to-coffee-50 rounded-2xl flex items-center justify-center mx-auto mb-4">
                    <Sparkles className="w-8 h-8 text-coffee-700" />
                  </div>
                  <h4 className="font-bold text-gray-900 mb-2">Специальные условия</h4>
                  <p className="text-sm text-gray-600">Лучшие тарифы и индивидуальные предложения</p>
                </div>
              </div>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  )
}

export default Testimonials

